class OrderBookMatchingService
  Result = Struct.new(:order, :trades, keyword_init: true)

  def self.place_and_match!(flight:, booking:, user:, side:, quantity_kg:, price_per_kg_cents:, payout_preference: "voucher", sync_dcs: true)
    new(
      flight: flight,
      booking: booking,
      user: user,
      side: side,
      quantity_kg: quantity_kg,
      price_per_kg_cents: price_per_kg_cents,
      payout_preference: payout_preference,
      sync_dcs: sync_dcs
    ).call!
  end

  def initialize(flight:, booking:, user:, side:, quantity_kg:, price_per_kg_cents:, payout_preference:, sync_dcs: true)
    @flight = flight
    @booking = booking
    @user = user
    @side = side.to_s
    @quantity_kg = quantity_kg.to_d
    @price_per_kg_cents = price_per_kg_cents.to_i
    @payout_preference = payout_preference.presence || "voucher"
    @sync_dcs = sync_dcs
  end

  def call!
    trades = []
    incoming_order = nil

    ActiveRecord::Base.transaction do
      # Deterministic lock order: Flight -> Incoming Booking -> Counterparty Orders -> Counterparty Bookings
      @flight.lock!
      @booking.lock!

      incoming_order = KiloOrder.create!(
        flight: @flight,
        passenger_booking: @booking,
        user: @user,
        side: @side,
        quantity_kg: @quantity_kg,
        remaining_kg: @quantity_kg,
        price_per_kg_cents: @price_per_kg_cents,
        payout_preference: @payout_preference,
        status: "open"
      )

      matching_candidates(incoming_order).each do |resting_order|
        break if incoming_order.remaining_kg.to_d <= 0

        resting_booking = resting_order.passenger_booking.lock!

        buy_order, sell_order, buyer_booking, seller_booking =
          if incoming_order.buy?
            [incoming_order, resting_order, @booking, resting_booking]
          else
            [resting_order, incoming_order, resting_booking, @booking]
          end

        # Enforce capacity and aircraft envelope strictly under lock
        max_buy_headroom = (buyer_booking.max_allowance_kg.to_d - buyer_booking.current_allowance_kg.to_d)
        max_sell_headroom = seller_booking.current_allowance_kg.to_d
        fill_kg = [
          incoming_order.remaining_kg.to_d,
          resting_order.remaining_kg.to_d,
          max_buy_headroom,
          max_sell_headroom
        ].min

        next if fill_kg <= 0

        # Price-Time Priority: execute at the resting (maker) order's limit price
        exec_price_cents = resting_order.price_per_kg_cents
        payout_type = sell_order.payout_preference

        econ = AirlineEconomicsService.trade_economics(
          flight: @flight,
          quantity_kg: fill_kg,
          execution_price_per_kg_cents: exec_price_cents,
          payout_type: payout_type
        )

        trade = KiloTrade.create!(
          flight: @flight,
          buy_order: buy_order,
          sell_order: sell_order,
          buyer: buy_order.user,
          seller: sell_order.user,
          quantity_kg: fill_kg,
          execution_price_per_kg_cents: exec_price_cents,
          gross_amount_cents: econ[:gross_amount_cents],
          airline_fee_cents: econ[:airline_fee_cents],
          seller_payout_cents: econ[:seller_payout_cents],
          payout_type: payout_type,
          estimated_fuel_cost_cents: econ[:estimated_fuel_cost_cents],
          airline_net_margin_cents: econ[:airline_net_margin_cents],
          buyer_savings_cents: econ[:buyer_savings_cents],
          executed_at: Time.current
        )

        # Atomic 1:1 PNR allowance transfer (zero net aircraft payload creep)
        seller_booking.update!(current_allowance_kg: seller_booking.current_allowance_kg.to_d - fill_kg)
        buyer_booking.update!(current_allowance_kg: buyer_booking.current_allowance_kg.to_d + fill_kg)

        # Credit airline flight voucher wallet immediately when seller chose voucher payout
        if payout_type == "voucher"
          seller_user = sell_order.user.lock!
          seller_user.update!(voucher_balance_cents: seller_user.voucher_balance_cents + econ[:seller_payout_cents])
        end

        decrement_order!(resting_order, fill_kg)
        decrement_order!(incoming_order, fill_kg)

        notify_counterparties!(trade, buyer_booking, seller_booking)
        trades << trade
      end
    end

    # Synchronize with the carrier's DCS/PSS outside the PostgreSQL row lock
    if @sync_dcs
      trades.each { |trade| AirlineDcs::SettlementOrchestrator.sync_trade!(trade) }
    end

    Result.new(order: incoming_order, trades: trades)
  end

  private

  def matching_candidates(incoming_order)
    base = @flight.kilo_orders.active
                  .where.not(user_id: incoming_order.user_id) # Strict anti-wash-trading
                  .lock

    if incoming_order.buy?
      base.where(side: "sell")
          .where("price_per_kg_cents <= ?", incoming_order.price_per_kg_cents)
          .order(price_per_kg_cents: :asc, created_at: :asc, id: :asc)
    else
      base.where(side: "buy")
          .where("price_per_kg_cents >= ?", incoming_order.price_per_kg_cents)
          .order(price_per_kg_cents: :desc, created_at: :asc, id: :asc)
    end
  end

  def decrement_order!(order, fill_kg)
    new_remaining = (order.remaining_kg.to_d - fill_kg).round(2)
    new_status = new_remaining <= 0 ? "filled" : "partially_filled"
    order.update!(remaining_kg: [new_remaining, 0.to_d].max, status: new_status)
  end

  def notify_counterparties!(trade, buyer_booking, seller_booking)
    price_str = format("€%.2f/kg", trade.execution_price_per_kg_cents / 100.0)
    qty_str = format("%g kg", trade.quantity_kg.to_f)
    payout_str = format("€%.2f", trade.seller_payout_cents / 100.0)

    Notification.notify(
      trade.buyer,
      @flight,
      "trade_bought",
      "Matched #{qty_str} on #{@flight.flight_number} at #{price_str}. PNR #{buyer_booking.pnr_code} updated to #{buyer_booking.current_allowance_kg.to_f} kg."
    )

    payout_label = trade.payout_type == "voucher" ? "#{payout_str} airline flight voucher credited" : "#{payout_str} cash payout queued"
    Notification.notify(
      trade.seller,
      @flight,
      "trade_sold",
      "Sold #{qty_str} on #{@flight.flight_number} at #{price_str} (#{payout_label}). PNR #{seller_booking.pnr_code} updated to #{seller_booking.current_allowance_kg.to_f} kg."
    )
  end
end

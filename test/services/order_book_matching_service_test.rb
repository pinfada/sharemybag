require "test_helper"

class OrderBookMatchingServiceTest < ActiveSupport::TestCase
  test "executes Price-Time Priority fractional fills at resting maker price and updates PNRs and vouchers atomically" do
    aircraft = create_aircraft_type(max_baggage_payload_kg: 7000.0, fuel_burn_rate_per_kg_hour: 0.035)
    flight = create_flight(
      aircraft_type: aircraft,
      flight_duration_hours: 5.5,
      airport_excess_fee_per_kg_cents: 1500,
      airline_commission_bps: 2500,
      base_booked_baggage_kg: 5000.0
    )

    seller_cheap = create_user(name: "Marie Light")
    seller_mid   = create_user(name: "Claire Light")
    buyer_heavy  = create_user(name: "Pierre Heavy")

    sb_cheap = create_booking(user: seller_cheap, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 23.0)
    sb_mid   = create_booking(user: seller_mid, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 23.0)
    bb_heavy = create_booking(user: buyer_heavy, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 23.0)

    # Resting ASK 1: 6 kg @ €6.00/kg (voucher)
    ask1 = OrderBookMatchingService.place_and_match!(
      flight: flight,
      booking: sb_cheap,
      user: seller_cheap,
      side: "sell",
      quantity_kg: 6.0,
      price_per_kg_cents: 600,
      payout_preference: "voucher"
    ).order

    # Resting ASK 2: 10 kg @ €7.00/kg (cash)
    ask2 = OrderBookMatchingService.place_and_match!(
      flight: flight,
      booking: sb_mid,
      user: seller_mid,
      side: "sell",
      quantity_kg: 10.0,
      price_per_kg_cents: 700,
      payout_preference: "cash"
    ).order

    # Incoming BID: 10 kg up to €7.50/kg -> matches 6 kg @ €6.00 (ask1) + 4 kg @ €7.00 (ask2)
    result = OrderBookMatchingService.place_and_match!(
      flight: flight,
      booking: bb_heavy,
      user: buyer_heavy,
      side: "buy",
      quantity_kg: 10.0,
      price_per_kg_cents: 750,
      payout_preference: "voucher"
    )

    assert_equal 2, result.trades.size
    assert_equal "filled", result.order.reload.status
    assert_in_delta 0.0, result.order.remaining_kg.to_f, 0.01

    assert_equal "filled", ask1.reload.status
    assert_in_delta 0.0, ask1.remaining_kg.to_f, 0.01

    assert_equal "partially_filled", ask2.reload.status
    assert_in_delta 6.0, ask2.remaining_kg.to_f, 0.01

    # Verify trade 1 (6 kg @ 600 cents = 3600 gross; 25% fee = 900; seller payout = 2700 voucher)
    trade1 = result.trades.first
    assert_in_delta 6.0, trade1.quantity_kg.to_f, 0.01
    assert_equal 600, trade1.execution_price_per_kg_cents
    assert_equal 3600, trade1.gross_amount_cents
    assert_equal 900, trade1.airline_fee_cents
    assert_equal 2700, trade1.seller_payout_cents
    assert_equal "voucher", trade1.payout_type
    assert_equal (1500 - 600) * 6, trade1.buyer_savings_cents

    # Verify trade 2 (4 kg @ 700 cents = 2800 gross; 25% fee = 700; seller payout = 2100 cash)
    trade2 = result.trades.second
    assert_in_delta 4.0, trade2.quantity_kg.to_f, 0.01
    assert_equal 700, trade2.execution_price_per_kg_cents
    assert_equal 2800, trade2.gross_amount_cents
    assert_equal 700, trade2.airline_fee_cents
    assert_equal 2100, trade2.seller_payout_cents
    assert_equal "cash", trade2.payout_type

    # PNR allowances updated atomically (total sum across flight unchanged = zero payload creep)
    assert_in_delta 17.0, sb_cheap.reload.current_allowance_kg.to_f, 0.01
    assert_in_delta 19.0, sb_mid.reload.current_allowance_kg.to_f, 0.01
    assert_in_delta 33.0, bb_heavy.reload.current_allowance_kg.to_f, 0.01
    assert bb_heavy.requires_split_bags?

    # Voucher credited to voucher seller only; cash seller voucher balance stays 0
    assert_equal 2700, seller_cheap.reload.voucher_balance_cents
    assert_equal 0, seller_mid.reload.voucher_balance_cents

    # Notifications created for buyer and both sellers
    assert_operator buyer_heavy.notifications.count, :>=, 2
    assert_operator seller_cheap.notifications.count, :>=, 1
    assert_operator seller_mid.notifications.count, :>=, 1
  end

  test "respects FIFO time priority when two asks have identical price" do
    flight = create_flight
    s1 = create_user(name: "First Seller")
    s2 = create_user(name: "Second Seller")
    b1 = create_user(name: "Buyer")

    sb1 = create_booking(user: s1, flight: flight)
    sb2 = create_booking(user: s2, flight: flight)
    bb1 = create_booking(user: b1, flight: flight)

    ask1 = OrderBookMatchingService.place_and_match!(flight: flight, booking: sb1, user: s1, side: "sell", quantity_kg: 5.0, price_per_kg_cents: 650).order
    ask2 = OrderBookMatchingService.place_and_match!(flight: flight, booking: sb2, user: s2, side: "sell", quantity_kg: 5.0, price_per_kg_cents: 650).order

    result = OrderBookMatchingService.place_and_match!(flight: flight, booking: bb1, user: b1, side: "buy", quantity_kg: 5.0, price_per_kg_cents: 650)

    assert_equal 1, result.trades.size
    assert_equal ask1.id, result.trades.first.sell_order_id
    assert_equal "filled", ask1.reload.status
    assert_equal "open", ask2.reload.status
  end

  test "cancels partially filled remainder cleanly without reversing executed trades" do
    flight = create_flight
    seller = create_user
    buyer = create_user
    sb = create_booking(user: seller, flight: flight)
    bb = create_booking(user: buyer, flight: flight)

    ask = OrderBookMatchingService.place_and_match!(flight: flight, booking: sb, user: seller, side: "sell", quantity_kg: 12.0, price_per_kg_cents: 650).order
    OrderBookMatchingService.place_and_match!(flight: flight, booking: bb, user: buyer, side: "buy", quantity_kg: 8.0, price_per_kg_cents: 700)

    assert_equal "partially_filled", ask.reload.status
    assert_in_delta 4.0, ask.remaining_kg.to_f, 0.01

    ask.cancel!
    assert_equal "cancelled", ask.reload.status
    assert_in_delta 0.0, ask.remaining_kg.to_f, 0.01
    # Executed 8 kg stays sold; seller can now sell remaining 15 kg
    assert_in_delta 15.0, sb.reload.current_allowance_kg.to_f, 0.01
    assert_in_delta 15.0, sb.available_to_sell_kg, 0.01
  end
end

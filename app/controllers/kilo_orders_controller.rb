class KiloOrdersController < ApplicationController
  before_action :signed_in_user
  before_action :set_flight
  before_action :set_order, only: [:cancel]

  def create
    @user_booking = @flight.passenger_bookings.find_by(user_id: current_user.id)
    unless @user_booking
      flash[:error] = t("kilo_orders.no_booking_on_flight")
      return redirect_to flight_path(@flight)
    end

    @kilo_order = KiloOrder.new(kilo_order_params)
    @kilo_order.flight = @flight
    @kilo_order.passenger_booking = @user_booking
    @kilo_order.user = current_user

    if @kilo_order.valid?
      result = OrderBookMatchingService.place_and_match!(
        flight: @flight,
        booking: @user_booking,
        user: current_user,
        side: @kilo_order.side,
        quantity_kg: @kilo_order.quantity_kg,
        price_per_kg_cents: @kilo_order.price_per_kg_cents,
        payout_preference: @kilo_order.payout_preference
      )

      if result.trades.any?
        trades = KiloTrade.where(id: result.trades.map(&:id))
        confirmed_kg = trades.confirmed.sum(:quantity_kg).to_f
        pending_kg = trades.where(dcs_sync_status: KiloTrade::UNRESOLVED_STATUSES).sum(:quantity_kg).to_f

        if confirmed_kg.positive?
          flash[:success] = t("kilo_orders.created_matched", matched_qty: confirmed_kg, flight: @flight.flight_number)
        end
        if pending_kg.positive?
          flash[:notice] = t("kilo_orders.awaiting_carrier", matched_qty: pending_kg)
        end
        if trades.where(dcs_sync_status: %w[failed compensated]).exists?
          flash[:error] = t("kilo_orders.carrier_rejected")
        end
      else
        side_label = result.order.buy? ? "BID (buy)" : "ASK (sell)"
        flash[:success] = t(
          "kilo_orders.created_resting",
          side: side_label,
          qty: result.order.quantity_kg.to_f,
          price: helpers.format_euros(result.order.price_per_kg_cents),
          flight: @flight.flight_number
        )
      end
      redirect_to flight_path(@flight)
    else
      load_flight_state_for_error
      render "flights/show", status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    @kilo_order = e.record.is_a?(KiloOrder) ? e.record : @kilo_order
    load_flight_state_for_error
    render "flights/show", status: :unprocessable_entity
  end

  def cancel
    if @kilo_order.user_id != current_user.id
      flash[:error] = t("common.unauthorized")
      return redirect_to flight_path(@flight)
    end

    if @kilo_order.cancel!
      flash[:notice] = t("kilo_orders.cancelled")
    else
      flash[:error] = t("kilo_orders.cannot_cancel")
    end
    redirect_to flight_path(@flight)
  end

  private

  def set_flight
    @flight = Flight.includes(:aircraft_type).find(params[:flight_id])
  end

  def set_order
    @kilo_order = @flight.kilo_orders.find(params[:id])
  end

  def kilo_order_params
    params.require(:kilo_order).permit(:side, :quantity_kg, :price_per_kg_euros, :payout_preference)
  end

  def load_flight_state_for_error
    @open_bids = @flight.open_bids.includes(:user)
    @open_asks = @flight.open_asks.includes(:user)
    @recent_trades = @flight.kilo_trades.confirmed.includes(:buyer, :seller).recent.limit(15)
    @flight_economics = AirlineEconomicsService.flight_summary(@flight)
    @flight_opportunity = AirlineEconomicsService.flight_opportunity(@flight)
    @user_orders = @flight.kilo_orders.where(user_id: current_user.id).recent
  end
end

class FlightsController < ApplicationController
  def index
    @flights = Flight.includes(:aircraft_type, :kilo_orders, :kilo_trades).upcoming

    if params[:q].present?
      term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @flights = @flights.joins(:aircraft_type).where(
        "flights.flight_number ILIKE :q OR flights.airline_name ILIKE :q OR flights.departure_iata ILIKE :q OR flights.arrival_iata ILIKE :q OR flights.departure_city ILIKE :q OR flights.arrival_city ILIKE :q OR aircraft_types.aircraft_name ILIKE :q",
        q: term
      )
    end

    if params[:airline].present?
      @flights = @flights.where(airline_code: params[:airline].strip.upcase)
    end

    @airlines = Flight.distinct.order(:airline_code).pluck(:airline_code, :airline_name)
    @fleet_summary = AirlineEconomicsService.fleet_summary(@flights)
  end

  def show
    @flight = Flight.includes(:aircraft_type).find(params[:id])
    load_flight_exchange_state
    @kilo_order = KiloOrder.new(
      side: default_order_side,
      quantity_kg: 8,
      price_per_kg_euros: default_limit_price_euros,
      payout_preference: "voucher"
    )
  end

  private

  def load_flight_exchange_state
    @open_bids = @flight.open_bids.includes(:user)
    @open_asks = @flight.open_asks.includes(:user)
    @recent_trades = @flight.kilo_trades.includes(:buyer, :seller).recent.limit(15)
    @flight_economics = AirlineEconomicsService.flight_summary(@flight)
    @user_booking = signed_in? ? @flight.passenger_bookings.find_by(user_id: current_user.id) : nil
    @user_orders = signed_in? ? @flight.kilo_orders.where(user_id: current_user.id).recent : KiloOrder.none
  end

  def default_order_side
    return "sell" unless @user_booking
    @user_booking.available_to_sell_kg >= 5 ? "sell" : "buy"
  end

  def default_limit_price_euros
    spot = @flight.spot_price_cents || 700
    format("%.2f", spot / 100.0)
  end
end

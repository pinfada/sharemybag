class WelcomeController < ApplicationController
  def home
    raw_flights = Flight.includes(:aircraft_type, :kilo_orders, :kilo_trades).upcoming.to_a
    @all_flights = raw_flights.sort_by do |f|
      [f.trading_open? ? 0 : 1, f.flight_number == "AF718" ? 0 : 1, f.departure_at]
    end

    @active_flight = select_active_flight(@all_flights, params[:flight])
    @fallback_open_flight = @all_flights.find(&:trading_open?)

    if @active_flight
      @active_opportunity = AirlineEconomicsService.flight_opportunity(@active_flight)
      @active_economics = AirlineEconomicsService.flight_summary(@active_flight)
      @top_bids = @active_flight.open_bids.limit(3).to_a
      @top_asks = @active_flight.open_asks.limit(3).to_a
    end

    @fleet_summary = AirlineEconomicsService.fleet_summary(Flight.all)
  end

  def how_it_works
  end

  def privacy
  end

  def accessibility
  end

  private

  def select_active_flight(flights, requested_code)
    return nil if flights.empty?

    if requested_code.present?
      matched = flights.find { |f| f.flight_number.casecmp?(requested_code.to_s.strip) }
      return matched if matched
    end

    flights.find { |f| f.flight_number == "AF718" && f.trading_open? } ||
      flights.find(&:trading_open?) ||
      flights.first
  end
end

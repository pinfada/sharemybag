class AirlineRoiController < ApplicationController
  def show
    @flights = Flight.includes(:aircraft_type, :kilo_trades, :kilo_orders).upcoming
    @fleet_summary = AirlineEconomicsService.fleet_summary(@flights)
    @flight_rows = @flights.map do |flight|
      {
        flight: flight,
        summary: AirlineEconomicsService.flight_summary(flight)
      }
    end
    @flagship_flight = @flights.find { |f| f.flight_number == "AF718" } || @flights.first
    @flagship_summary = @flagship_flight ? AirlineEconomicsService.flight_summary(@flagship_flight) : nil

    @default_projection = AirlineEconomicsService.annual_fleet_projection(
      daily_flights: 120,
      avg_matched_kg_per_flight: 120.0,
      avg_spot_price_euros: 7.50,
      commission_percent: 25.0,
      voucher_adoption_percent: 75.0,
      avg_flight_duration_hours: 4.5,
      airport_excess_fee_euros: 15.0,
      cannibalization_percent: 6.0,
      booking_cannibalization_percent: 15.0,
      preflight_bag_fee_euros: 10.0,
      unused_allowance_percent: 35.0
    )
    @fleet_ghost_kg = @flights.sum { |f| AirlineEconomicsService.flight_opportunity(f)[:ghost_allowance_kg] }.round(1)
  end
end

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
    @default_projection = AirlineEconomicsService.annual_fleet_projection(
      daily_flights: 120,
      avg_matched_kg_per_flight: 180.0,
      avg_spot_price_euros: 7.50,
      commission_percent: 25.0,
      voucher_adoption_percent: 75.0,
      avg_flight_duration_hours: 4.5,
      airport_excess_fee_euros: 15.0,
      cannibalization_percent: 6.0
    )
    @fleet_ghost_kg = @flights.sum { |f| AirlineEconomicsService.flight_opportunity(f)[:ghost_allowance_kg] }.round(1)
  end
end

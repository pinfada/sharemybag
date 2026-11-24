class WelcomeController < ApplicationController
  def home
    @featured_flights = Flight.includes(:aircraft_type, :kilo_orders, :kilo_trades)
                              .upcoming
                              .limit(3)
    @fleet_summary = AirlineEconomicsService.fleet_summary(Flight.all)
    @stats = {
      live_flights: Flight.active_exchange.count,
      matched_kg: @fleet_summary[:matched_kg],
      airline_net_margin_cents: @fleet_summary[:airline_net_margin_cents],
      retained_cash_cents: @fleet_summary[:total_cash_retained_cents],
      passenger_savings_cents: @fleet_summary[:passenger_savings_cents]
    }
  end

  def how_it_works
  end

  def privacy
  end

  def accessibility
  end
end

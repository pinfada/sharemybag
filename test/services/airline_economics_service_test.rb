require "test_helper"

class AirlineEconomicsServiceTest < ActiveSupport::TestCase
  test "calculates transparent marginal fuel cost, 25% commission, retained voucher cash, net margin and passenger savings" do
    aircraft = create_aircraft_type(fuel_burn_rate_per_kg_hour: 0.035)
    flight = create_flight(
      aircraft_type: aircraft,
      flight_duration_hours: 5.5,
      airport_excess_fee_per_kg_cents: 1500,
      airline_commission_bps: 2500
    )

    # 10 kg traded @ €7.00/kg = €70.00 gross (7000 cents)
    # Commission 25% = 1750 cents (€17.50)
    # Seller payout = 5250 cents (€52.50) -> voucher retained in airline ecosystem
    # Marginal fuel burn = 10 kg * 0.035 * 5.5 h = 1.925 kg Jet-A1 * €1.10/kg = €2.1175 -> 212 cents
    # Airline net margin = 1750 - 212 = 1538 cents (€15.38)
    # Buyer savings vs airport €15/kg = (1500 - 700) * 10 = 8000 cents (€80.00)
    metrics = AirlineEconomicsService.trade_economics(
      flight: flight,
      quantity_kg: 10.0,
      execution_price_per_kg_cents: 700,
      payout_type: "voucher"
    )

    assert_equal 7000, metrics[:gross_amount_cents]
    assert_equal 1750, metrics[:airline_fee_cents]
    assert_equal 5250, metrics[:seller_payout_cents]
    assert_equal 212, metrics[:estimated_fuel_cost_cents]
    assert_equal 1538, metrics[:airline_net_margin_cents]
    assert_equal 8000, metrics[:buyer_savings_cents]
  end

  test "aggregates flight and fleet economics accurately" do
    flight = create_flight(flight_duration_hours: 6.0, airport_excess_fee_per_kg_cents: 1500, airline_commission_bps: 2500)
    s1 = create_user
    s2 = create_user
    b1 = create_user
    sb1 = create_booking(user: s1, flight: flight)
    sb2 = create_booking(user: s2, flight: flight)
    bb1 = create_booking(user: b1, flight: flight)

    OrderBookMatchingService.place_and_match!(flight: flight, booking: sb1, user: s1, side: "sell", quantity_kg: 10.0, price_per_kg_cents: 700, payout_preference: "voucher")
    OrderBookMatchingService.place_and_match!(flight: flight, booking: sb2, user: s2, side: "sell", quantity_kg: 5.0, price_per_kg_cents: 800, payout_preference: "cash")
    OrderBookMatchingService.place_and_match!(flight: flight, booking: bb1, user: b1, side: "buy", quantity_kg: 15.0, price_per_kg_cents: 850)

    summary = AirlineEconomicsService.flight_summary(flight)
    assert_in_delta 15.0, summary[:matched_kg], 0.01
    assert_equal 2, summary[:trades_count]
    assert_equal 11000, summary[:gross_volume_cents]       # 7000 + 4000
    assert_equal 2750, summary[:airline_commission_cents]  # 1750 + 1000
    assert_equal 5250, summary[:retained_voucher_cents]    # only voucher trade retained
    assert_equal 5250 + 2750, summary[:total_cash_retained_cents]
    assert_operator summary[:estimated_fuel_cost_cents], :>, 0
    assert_equal summary[:airline_commission_cents] - summary[:estimated_fuel_cost_cents], summary[:airline_net_margin_cents]
    assert_equal (1500 - 700) * 10 + (1500 - 800) * 5, summary[:passenger_savings_cents]

    fleet = AirlineEconomicsService.fleet_summary(
      Flight.includes(:aircraft_type, :kilo_orders, :kilo_trades).where(id: flight.id).upcoming
    )
    assert_equal summary[:gross_volume_cents], fleet[:gross_volume_cents]
    assert_equal 1, fleet[:flights_count]
  end

  test "projects annual fleet ROI transparently including pre-flight booking cannibalization, counter haircut, unused sensitivity, and conservative-to-base range" do
    projection = AirlineEconomicsService.annual_fleet_projection(
      daily_flights: 100,
      avg_matched_kg_per_flight: 180.0,
      avg_spot_price_euros: 7.5,
      commission_percent: 25.0,
      voucher_adoption_percent: 70.0,
      avg_flight_duration_hours: 4.5,
      airport_excess_fee_euros: 15.0,
      cannibalization_percent: 6.0,
      booking_cannibalization_percent: 15.0,
      preflight_bag_fee_euros: 10.0,
      unused_allowance_percent: 35.0
    )

    assert_equal 36_500, projection[:annual_flights]
    assert_in_delta 6_570_000.0, projection[:annual_matched_kg], 0.1
    assert_operator projection[:annual_gross_volume_cents], :>, 0
    assert_operator projection[:annual_net_margin_cents], :>, 0
    assert_operator projection[:annual_cannibalization_deduction_cents], :>, 0
    assert_operator projection[:annual_booking_cannibalization_deduction_cents], :>, 0
    assert_operator projection[:annual_incremental_profit_low_cents], :<, projection[:annual_incremental_profit_cents]
    assert_operator projection[:annual_retained_voucher_cents], :>, 0
    assert_operator projection[:annual_passenger_savings_cents], :>, 0
    assert_operator projection[:annual_checkin_hours_saved], :>, 0

    # Sensitivity: cutting unused allowance benchmark from 35% to 20% scales matched volume down proportionally
    lower_unused = AirlineEconomicsService.annual_fleet_projection(
      daily_flights: 100,
      avg_matched_kg_per_flight: 180.0,
      unused_allowance_percent: 20.0
    )
    assert_operator lower_unused[:annual_matched_kg], :<, projection[:annual_matched_kg]
  end

  test "calculates Ghost Allowance uncaptured opportunity, belly cargo comparison, and check-in minutes saved per flight" do
    aircraft = create_aircraft_type(max_baggage_payload_kg: 7452.0, fuel_burn_rate_per_kg_hour: 0.035)
    flight = create_flight(
      aircraft_type: aircraft,
      base_booked_baggage_kg: 5600.0,
      flight_duration_hours: 5.5,
      airport_excess_fee_per_kg_cents: 1500,
      airline_commission_bps: 2500
    )

    opp = AirlineEconomicsService.flight_opportunity(flight)
    assert_in_delta 1960.0, opp[:ghost_allowance_kg], 0.1 # 35% of 5600 kg booked allowance typically flies empty
    assert_in_delta 3640.0, opp[:used_baggage_kg], 0.1
    assert_operator opp[:capturable_kg], :>, 0
    assert_operator opp[:uncaptured_net_margin_cents], :>, 0
    assert_equal 280, opp[:belly_cargo_yield_per_kg_cents]
    assert_operator opp[:exchange_gross_yield_per_kg_cents], :>, opp[:belly_cargo_yield_per_kg_cents]
    assert_operator opp[:checkin_minutes_saved], :>=, 0
  end
end

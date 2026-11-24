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

  test "projects annual fleet ROI transparently including pre-flight booking cannibalization, counter haircut, unused sensitivity, voucher redemption, and sign-aware range" do
    projection = AirlineEconomicsService.annual_fleet_projection(
      daily_flights: 120,
      avg_matched_kg_per_flight: 120.0,
      avg_spot_price_euros: 7.5,
      commission_percent: 25.0,
      voucher_adoption_percent: 75.0,
      voucher_redemption_percent: 75.0,
      avg_flight_duration_hours: 4.5,
      airport_excess_fee_euros: 15.0,
      cannibalization_percent: 6.0,
      booking_cannibalization_percent: 15.0,
      preflight_bag_fee_euros: 10.0,
      unused_allowance_percent: 35.0
    )

    # 120 flights/day * 365 * 120 kg = 5,256,000 kg/yr
    assert_equal 43_800, projection[:annual_flights]
    assert_in_delta 5_256_000.0, projection[:annual_matched_kg], 0.1

    # Bug #2 regression: exact gross counterfactual cannibalization (ZERO fuel credit deducted)
    # 15% * 5,256,000 * €10 = €7,884,000 (788,400,000 cents)
    assert_equal 788_400_000, projection[:annual_booking_cannibalization_deduction_cents]
    # 6% * 5,256,000 * €15 = €4,730,400 (473,040,000 cents)
    assert_equal 473_040_000, projection[:annual_cannibalization_deduction_cents]

    # Structural transparency: ex-voucher cash result exposed explicitly
    expected_ex_voucher = projection[:annual_net_margin_cents] -
                          projection[:annual_booking_cannibalization_deduction_cents] -
                          projection[:annual_cannibalization_deduction_cents]
    assert_equal expected_ex_voucher, projection[:annual_ex_voucher_profit_cents]

    # Voucher redemption rate controls voucher contribution (0% redemption -> €0 voucher contribution)
    zero_redemption = AirlineEconomicsService.annual_fleet_projection(
      daily_flights: 120,
      avg_matched_kg_per_flight: 120.0,
      voucher_redemption_percent: 0.0
    )
    assert_equal 0, zero_redemption[:annual_voucher_rebooking_margin_cents]
    assert_equal zero_redemption[:annual_ex_voucher_profit_cents], zero_redemption[:annual_incremental_profit_cents]

    # Positive base case: conservative low < base
    assert_operator projection[:annual_incremental_profit_cents], :>, 0
    assert_operator projection[:annual_incremental_profit_low_cents], :<, projection[:annual_incremental_profit_cents]

    # Bug #1 regression: negative base case (e.g. booking fee €20/kg) keeps conservative floor STRICTLY WORSE than base (never inverted!)
    negative_case = AirlineEconomicsService.annual_fleet_projection(
      daily_flights: 120,
      avg_matched_kg_per_flight: 120.0,
      preflight_bag_fee_euros: 20.0,
      booking_cannibalization_percent: 15.0,
      cannibalization_percent: 6.0,
      voucher_redemption_percent: 75.0
    )
    assert_equal 1_576_800_000, negative_case[:annual_booking_cannibalization_deduction_cents] # exact €15,768,000
    assert_operator negative_case[:annual_incremental_profit_cents], :<, 0
    assert_operator negative_case[:annual_incremental_profit_low_cents], :<, negative_case[:annual_incremental_profit_cents]

    # Sensitivity: cutting unused allowance benchmark from 35% to 20% scales matched volume down proportionally
    lower_unused = AirlineEconomicsService.annual_fleet_projection(
      daily_flights: 120,
      avg_matched_kg_per_flight: 120.0,
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

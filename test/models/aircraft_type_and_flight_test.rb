require "test_helper"

class AircraftTypeAndFlightTest < ActiveSupport::TestCase
  test "aircraft type enforces positive capacity and certified baggage payload" do
    aircraft = create_aircraft_type(
      code: "A350-900",
      aircraft_name: "Airbus A350-900",
      seat_capacity: 324,
      default_baggage_kg_per_pax: 23.0,
      max_baggage_payload_kg: 7452.0
    )
    assert aircraft.valid?
    assert_in_delta 7452.0, aircraft.max_baggage_payload_kg.to_f, 0.01

    invalid = AircraftType.new(code: "", seat_capacity: 0, max_baggage_payload_kg: -10)
    assert_not invalid.valid?
  end

  test "flight trading_open? enforces H-4h weight and balance cutoff" do
    open_flight = create_flight(departure_at: 10.hours.from_now, status: "open")
    assert open_flight.trading_open?

    cutoff_flight = create_flight(departure_at: 3.hours.from_now, status: "open")
    assert_not cutoff_flight.trading_open?

    closed_flight = create_flight(departure_at: 24.hours.from_now, status: "closed")
    assert_not closed_flight.trading_open?
  end

  test "flight rejects base_booked_baggage_kg exceeding aircraft max_baggage_payload_kg" do
    aircraft = create_aircraft_type(max_baggage_payload_kg: 3000.0)
    flight = Flight.new(
      flight_number: "AF999",
      airline_name: "Air France",
      airline_code: "AF",
      aircraft_type: aircraft,
      departure_iata: "CDG",
      departure_city: "Paris",
      arrival_iata: "DKR",
      arrival_city: "Dakar",
      departure_at: 24.hours.from_now,
      flight_duration_hours: 5.5,
      airport_excess_fee_per_kg_cents: 1500,
      airline_commission_bps: 2500,
      base_booked_baggage_kg: 3500.0,
      status: "open"
    )
    assert_not flight.valid?
    assert flight.errors[:base_booked_baggage_kg].any?
  end

  test "flight order book metrics: best_bid, best_ask, spread, spot_price, demand, supply and payload utilization" do
    aircraft = create_aircraft_type(max_baggage_payload_kg: 5000.0)
    flight = create_flight(aircraft_type: aircraft, base_booked_baggage_kg: 3500.0)

    seller1 = create_user
    seller2 = create_user
    buyer1 = create_user
    buyer2 = create_user

    sb1 = create_booking(user: seller1, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 23.0)
    sb2 = create_booking(user: seller2, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 23.0)
    bb1 = create_booking(user: buyer1, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 23.0)
    bb2 = create_booking(user: buyer2, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 23.0)

    KiloOrder.create!(flight: flight, passenger_booking: sb1, user: seller1, side: "sell", quantity_kg: 10.0, remaining_kg: 10.0, price_per_kg_cents: 800, payout_preference: "voucher")
    KiloOrder.create!(flight: flight, passenger_booking: sb2, user: seller2, side: "sell", quantity_kg: 8.0, remaining_kg: 8.0, price_per_kg_cents: 900, payout_preference: "voucher")
    KiloOrder.create!(flight: flight, passenger_booking: bb1, user: buyer1, side: "buy", quantity_kg: 6.0, remaining_kg: 6.0, price_per_kg_cents: 700, payout_preference: "voucher")
    KiloOrder.create!(flight: flight, passenger_booking: bb2, user: buyer2, side: "buy", quantity_kg: 9.0, remaining_kg: 9.0, price_per_kg_cents: 650, payout_preference: "voucher")

    assert_equal 700, flight.best_bid_cents
    assert_equal 800, flight.best_ask_cents
    assert_equal 100, flight.spread_cents
    assert_equal 750, flight.spot_price_cents # midpoint when no trade yet
    assert_in_delta 15.0, flight.total_demand_kg, 0.01
    assert_in_delta 18.0, flight.total_supply_kg, 0.01
    assert_in_delta 70.0, flight.payload_utilization_percent, 0.1
    assert_in_delta 1500.0, flight.remaining_payload_headroom_kg, 0.01
  end
end

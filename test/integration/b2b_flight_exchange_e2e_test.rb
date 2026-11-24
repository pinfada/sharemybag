require "test_helper"

class B2bFlightExchangeE2eTest < ActionDispatch::IntegrationTest
  test "full end-to-end B2B baggage allowance exchange: ASK -> crossing BID -> atomic PNR update, voucher credit, airline ROI, and cancellation" do
    aircraft = create_aircraft_type(
      code: "A350-900",
      aircraft_name: "Airbus A350-900",
      seat_capacity: 324,
      max_baggage_payload_kg: 7452.0,
      fuel_burn_rate_per_kg_hour: 0.035
    )
    flight = create_flight(
      aircraft_type: aircraft,
      flight_number: "AF718",
      airline_name: "Air France",
      airline_code: "AF",
      departure_iata: "CDG",
      departure_city: "Paris",
      arrival_iata: "DKR",
      arrival_city: "Dakar",
      flight_duration_hours: 5.5,
      airport_excess_fee_per_kg_cents: 1500,
      airline_commission_bps: 2500,
      base_booked_baggage_kg: 5200.0
    )

    marie = create_user(name: "Marie Light", email: "marie.e2e@example.com")
    pierre = create_user(name: "Pierre Heavy", email: "pierre.e2e@example.com")

    marie_booking = create_booking(user: marie, flight: flight, pnr_code: "AF718M", base_allowance_kg: 23.0, current_allowance_kg: 23.0)
    pierre_booking = create_booking(user: pierre, flight: flight, pnr_code: "AF718P", base_allowance_kg: 23.0, current_allowance_kg: 23.0)

    # 1. Public visitor inspects live flights & flight order book
    get flights_path
    assert_response :success
    assert_includes response.body, "AF718"
    assert_includes response.body, "Airbus A350-900"

    # 2. Marie (light traveler) signs in and posts an ASK: 12 kg @ €6.50/kg (voucher)
    sign_in_as(marie)
    assert_difference "KiloOrder.count", 1 do
      post flight_kilo_orders_path(flight), params: {
        kilo_order: {
          side: "sell",
          quantity_kg: 12,
          price_per_kg_euros: "6.50",
          payout_preference: "voucher"
        }
      }
    end
    assert_redirected_to flight_path(flight)
    marie_ask = KiloOrder.last
    assert_equal "open", marie_ask.status
    assert_in_delta 12.0, marie_ask.remaining_kg.to_f, 0.01

    delete signout_path

    # 3. Pierre (heavy traveler) signs in and posts a crossing BID: 10 kg @ €7.50/kg
    sign_in_as(pierre)
    assert_difference "KiloTrade.count", 1 do
      post flight_kilo_orders_path(flight), params: {
        kilo_order: {
          side: "buy",
          quantity_kg: 10,
          price_per_kg_euros: "7.50",
          payout_preference: "voucher"
        }
      }
    end
    assert_redirected_to flight_path(flight)
    follow_redirect!
    assert_response :success

    # Verify atomic settlement: 10 kg executed at Marie's maker price €6.50/kg = €65.00 gross
    # Airline fee 25% = €16.25 (1625 cents), Marie voucher payout = €48.75 (4875 cents)
    trade = KiloTrade.last
    assert_in_delta 10.0, trade.quantity_kg.to_f, 0.01
    assert_equal 650, trade.execution_price_per_kg_cents
    assert_equal 6500, trade.gross_amount_cents
    assert_equal 1625, trade.airline_fee_cents
    assert_equal 4875, trade.seller_payout_cents

    assert_in_delta 13.0, marie_booking.reload.current_allowance_kg.to_f, 0.01
    assert_in_delta 33.0, pierre_booking.reload.current_allowance_kg.to_f, 0.01
    assert_equal 4875, marie.reload.voucher_balance_cents

    # Pierre checks /my-bookings -> sees 33 kg allowance and IATA 32 kg split-bag safety notice
    get my_bookings_path
    assert_response :success
    assert_includes response.body, "AF718P"
    assert_includes response.body, "33"
    assert_includes response.body, "32 kg"

    # Airline ROI dashboard reflects the real executed trade transparently
    get airline_roi_path
    assert_response :success
    assert_includes response.body, "€65.00"
    assert_includes response.body, "€16.25"
    assert_includes response.body, "€48.75"

    delete signout_path

    # 4. Marie signs back in, sees her €48.75 flight voucher balance, and cancels her remaining 2 kg ASK
    sign_in_as(marie)
    get my_bookings_path
    assert_response :success
    assert_includes response.body, "€48.75"

    patch cancel_flight_kilo_order_path(flight, marie_ask)
    assert_redirected_to flight_path(flight)
    assert_equal "cancelled", marie_ask.reload.status
    assert_in_delta 0.0, marie_ask.remaining_kg.to_f, 0.01
  end
end

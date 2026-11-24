require "test_helper"

class HomeExchangeDeskTest < ActionDispatch::IntegrationTest
  test "home page opens directly on the live flagship flight exchange desk with flight switcher and 3-party preview" do
    af = create_flight(flight_number: "AF718", airline_name: "Air France", airline_code: "AF", departure_iata: "CDG", arrival_iata: "DKR", base_booked_baggage_kg: 5680.0)
    ba = create_flight(flight_number: "BA075", airline_name: "British Airways", airline_code: "BA", departure_iata: "LHR", arrival_iata: "LOS", base_booked_baggage_kg: 6890.0)

    seller = create_user
    buyer = create_user
    sb = create_booking(user: seller, flight: af)
    bb = create_booking(user: buyer, flight: af)
    OrderBookMatchingService.place_and_match!(flight: af, booking: sb, user: seller, side: "sell", quantity_kg: 7, price_per_kg_cents: 800)
    OrderBookMatchingService.place_and_match!(flight: af, booking: bb, user: buyer, side: "buy", quantity_kg: 8, price_per_kg_cents: 750)

    get root_path
    assert_response :success
    assert_select "h1", 1
    assert_select "[data-home-flight-switcher]", 1
    assert_select "[data-home-live-book]", 1
    assert_select "[data-home-trade-sim]", 1
    assert_select "[aria-live='polite'][data-home-sim-output]", 1
    assert_includes response.body, "AF718"
    assert_includes response.body, "€7.50"
    assert_includes response.body, "€8.00"

    # Switching flight via query parameter updates the desk to BA075
    get root_path(flight: ba.flight_number)
    assert_response :success
    assert_includes response.body, "BA075"
    assert_includes response.body, "LHR"
  end

  test "home page handles adverse state gracefully: H-4h Weight & Balance cutoff reached, empty book, and long carrier/city labels" do
    open_flight = create_flight(
      flight_number: "AF718",
      departure_at: 18.hours.from_now,
      status: "open"
    )
    cutoff_flight = create_flight(
      flight_number: "SN372",
      airline_name: "Brussels Airlines — Intercontinental Long-Haul",
      airline_code: "SN",
      departure_iata: "BRU",
      departure_city: "Brussels National Zaventem",
      arrival_iata: "FIH",
      arrival_city: "Kinshasa N'Djili International",
      departure_at: 2.5.hours.from_now,
      status: "open"
    )

    get root_path(flight: cutoff_flight.flight_number)
    assert_response :success
    assert_select "h1", 1
    assert_select "[data-adverse-cutoff-state]", 1
    assert_includes response.body, "SN372"
    assert_includes response.body, "Weight &amp; Balance Cutoff"
    # Provides clear fallback CTA back to an open departure
    assert_select "a[href='#{root_path(flight: open_flight.flight_number)}']", { minimum: 1 }
  end

  test "home page renders cleanly even when zero flights exist in database" do
    get root_path
    assert_response :success
    assert_select "h1", 1
    assert_select "[data-empty-fleet-state]", 1
  end
end

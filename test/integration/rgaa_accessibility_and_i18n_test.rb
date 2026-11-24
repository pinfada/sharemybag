require "test_helper"

class RgaaAccessibilityAndI18nTest < ActionDispatch::IntegrationTest
  test "all public pages use lang=en, RGAA landmarks, skip link, bespoke SVG logo, and a single h1" do
    flight = create_flight(flight_number: "AF718", departure_iata: "CDG", arrival_iata: "DKR")

    [
      root_path,
      flights_path,
      flight_path(flight),
      airline_roi_path,
      how_it_works_path,
      privacy_path,
      accessibility_path,
      signin_path,
      signup_path
    ].each do |path|
      get path
      assert_response :success, "Expected 200 on #{path}"
      assert_select "html[lang='en']", 1, "Missing lang='en' on #{path}"
      assert_select "title", /ShareMyBag/, "Missing ShareMyBag in title on #{path}"
      assert_select "a.smb-skip-link[href='#main-content']", 1, "Missing RGAA skip link on #{path}"
      assert_select "header[role='banner']", 1, "Missing banner landmark on #{path}"
      assert_select "nav[aria-label]", { minimum: 1 }, "Missing labeled nav on #{path}"
      assert_select "main#main-content[tabindex='-1']", 1, "Missing main landmark on #{path}"
      assert_select "footer[role='contentinfo']", 1, "Missing contentinfo landmark on #{path}"
      assert_select "h1", 1, "Expected exactly one h1 on #{path}"
      assert_select "link[rel='icon'][href='/favicon.svg']", 1, "Missing favicon on #{path}"
      assert_select "header svg.smb-logo-svg", 1, "Missing bespoke SVG logo on #{path}"
    end
  end

  test "primary navigation sets aria-current='page' on active routes" do
    get flights_path
    assert_response :success
    assert_select "nav a.nav-link[aria-current='page']", text: /Live Flights/i

    get airline_roi_path
    assert_response :success
    assert_select "nav a.nav-link[aria-current='page']", text: /Airline ROI/i
  end

  test "flight order book uses accessible tables with scope=col, fieldset/legend, and aria-live estimator" do
    flight = create_flight(flight_number: "AF718")
    passenger = create_user(name: "Marie Light")
    create_booking(user: passenger, flight: flight, pnr_code: "AF718M")

    sign_in_as(passenger)
    get flight_path(flight)
    assert_response :success

    assert_select "table th[scope='col']", { minimum: 4 }
    assert_select "fieldset legend", { minimum: 1 }
    assert_select "input[required][aria-required='true']", { minimum: 2 }
    assert_select "[aria-live='polite'][data-order-estimate-output]", 1

    # Invalid order triggers role='alert' and aria-invalid='true'
    post flight_kilo_orders_path(flight), params: {
      kilo_order: {
        side: "sell",
        quantity_kg: 99,
        price_per_kg_euros: "0.10",
        payout_preference: "voucher"
      }
    }
    assert_response :unprocessable_entity
    assert_select "[role='alert']", { minimum: 1 }
    assert_select "[aria-invalid='true']", { minimum: 1 }
  end

  test "airline ROI page provides an accessible interactive fleet simulator with aria-live output" do
    get airline_roi_path
    assert_response :success
    assert_select "[data-roi-simulator]", 1
    assert_select "[aria-live='polite'][data-roi-annual-margin]", 1
  end

  test "accessibility statement page declares RGAA 4.1 and WCAG 2.1 AA and is linked in footer" do
    get root_path
    assert_select "footer a[href='#{accessibility_path}']", /Accessibility/i

    get accessibility_path
    assert_response :success
    assert_includes response.body, "RGAA"
    assert_includes response.body, "WCAG 2.1"
  end
end

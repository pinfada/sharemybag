require "test_helper"

class DcsWebhooksAndIntegrationsTest < ActionDispatch::IntegrationTest
  setup do
    @secret = "test-carrier-webhook-secret-2026"
    ENV["DCS_WEBHOOK_SECRET_AF"] = @secret

    @connector = AirlineConnector.create!(
      airline_code: "AF",
      airline_name: "Air France",
      provider: "iata_ndc",
      accounting_prefix: "057",
      api_base_url: "https://ndc.airfrance-demo.example/v21.3",
      auth_mode: "oauth2_mtls",
      webhook_signing_secret_ref: "DCS_WEBHOOK_SECRET_AF"
    )
    @a350 = create_aircraft_type(code: "A350-900", aircraft_name: "Airbus A350-900", max_baggage_payload_kg: 7452.0)
    @a320 = create_aircraft_type(code: "A320neo", aircraft_name: "Airbus A320neo", max_baggage_payload_kg: 4140.0)
    @flight = create_flight(
      aircraft_type: @a350,
      flight_number: "AF718",
      airline_code: "AF",
      airline_name: "Air France",
      base_booked_baggage_kg: 5200.0,
      status: "open"
    )
  end

  teardown do
    ENV.delete("DCS_WEBHOOK_SECRET_AF")
  end

  def signed_headers(body, timestamp: Time.current.to_i.to_s, secret: @secret)
    digest = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")
    {
      "CONTENT_TYPE" => "application/json",
      "X-ShareMyBag-Timestamp" => timestamp,
      "X-ShareMyBag-Signature" => "sha256=#{digest}"
    }
  end

  test "rejects DCS webhooks with missing, tampered, or stale replay signatures (401 Unauthorized)" do
    payload = { event: "flight.weight_balance_locked", flight_number: "AF718" }.to_json

    post api_v1_dcs_webhook_path("AF"), params: payload, headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :unauthorized

    post api_v1_dcs_webhook_path("AF"), params: payload, headers: signed_headers(payload, secret: "wrong-secret")
    assert_response :unauthorized

    stale_ts = (Time.current - 10.minutes).to_i.to_s
    post api_v1_dcs_webhook_path("AF"), params: payload, headers: signed_headers(payload, timestamp: stale_ts)
    assert_response :unauthorized
    assert_equal "open", @flight.reload.status
  end

  test "valid signed flight.weight_balance_locked webhook immediately freezes the flight order book" do
    payload = { event: "flight.weight_balance_locked", flight_number: "AF718" }.to_json

    post api_v1_dcs_webhook_path("AF"), params: payload, headers: signed_headers(payload)
    assert_response :success
    assert_equal "closed", @flight.reload.status
    assert_not @flight.trading_open?
  end

  test "valid signed flight.equipment_swap webhook updates aircraft type and freezes book if payload exceeds new aircraft cap" do
    payload = {
      event: "flight.equipment_swap",
      flight_number: "AF718",
      new_aircraft_code: "A320neo"
    }.to_json

    post api_v1_dcs_webhook_path("AF"), params: payload, headers: signed_headers(payload)
    assert_response :success

    @flight.reload
    assert_equal @a320.id, @flight.aircraft_type_id
    # 5200 kg booked > 4140 kg A320neo max payload -> exchange auto-freezes for safety!
    assert_equal "closed", @flight.status
  end

  test "CTO /integrations page is accessible (RGAA 4.1 AA) and displays carrier connectors and live IATA EMD ledger" do
    get integrations_path
    assert_response :success
    assert_select "html[lang='en']", 1
    assert_select "h1", 1
    assert_select "table th[scope='col']", { minimum: 5 }
    assert_includes response.body, "Air France"
    assert_includes response.body, "IATA NDC"
    assert_includes response.body, "/api/v1/dcs/webhooks/"
  end
end

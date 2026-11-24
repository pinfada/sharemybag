require "test_helper"

class AirlineDcsSettlementOrchestratorTest < ActiveSupport::TestCase
  test "AirlineConnector enforces HTTPS-only and blocks SSRF loopback/private metadata endpoints" do
    valid = AirlineConnector.new(
      airline_code: "AF",
      airline_name: "Air France",
      provider: "iata_ndc",
      accounting_prefix: "057",
      api_base_url: "https://api.airfrance-klm.example/ndc/v2",
      auth_mode: "oauth2_mtls"
    )
    assert valid.valid?

    %w[
      http://api.airfrance-klm.example/ndc
      https://127.0.0.1/internal
      https://localhost:8080/admin
      https://169.254.169.254/latest/meta-data
      https://10.0.0.5/dcs
    ].each do |unsafe_url|
      bad = AirlineConnector.new(
        airline_code: "XX",
        airline_name: "Unsafe",
        provider: "webhook_rest",
        accounting_prefix: "999",
        api_base_url: unsafe_url,
        auth_mode: "hmac_bearer"
      )
      assert_not bad.valid?, "Expected SSRF/HTTP URL #{unsafe_url} to be rejected"
      assert bad.errors[:api_base_url].any?
    end
  end

  test "syncs matched trade end-to-end with IATA EMD-A, seller DCS adjustment, and voucher EMD-S, and is strictly idempotent" do
    connector = AirlineConnector.create!(
      airline_code: "AF",
      airline_name: "Air France",
      provider: "sandbox",
      accounting_prefix: "057",
      auth_mode: "sandbox"
    )
    flight = create_flight(airline_code: "AF", airline_name: "Air France", flight_number: "AF718")
    seller = create_user(name: "Marie Seller")
    buyer  = create_user(name: "Pierre Buyer")
    sb = create_booking(user: seller, flight: flight, pnr_code: "AF718M")
    bb = create_booking(user: buyer, flight: flight, pnr_code: "AF718P")

    OrderBookMatchingService.place_and_match!(
      flight: flight, booking: sb, user: seller,
      side: "sell", quantity_kg: 10, price_per_kg_cents: 750, payout_preference: "voucher"
    )
    result = OrderBookMatchingService.place_and_match!(
      flight: flight, booking: bb, user: buyer,
      side: "buy", quantity_kg: 10, price_per_kg_cents: 800
    )

    trade = result.trades.first.reload
    assert_equal "synced", trade.dcs_sync_status
    assert_match(/\A057-\d{10}\z/, trade.buyer_emd_reference)
    assert_match(/\A057-\d{10}\z/, trade.seller_voucher_emd_reference)
    assert trade.dcs_synced_at.present?

    events = trade.dcs_sync_events.order(:id)
    assert_equal 3, events.size
    assert_equal %w[issue_buyer_emd_a adjust_seller_allowance issue_seller_voucher_emd_s], events.map(&:operation)
    assert_equal "C", events.first.iata_rfic
    assert_equal "0GO", events.first.iata_rfisc
    assert_equal "XBAG", events.first.ssr_code
    assert_equal "D", events.last.iata_rfic
    assert_equal "99I", events.last.iata_rfisc
    assert_equal connector.id, events.first.airline_connector_id

    assert_equal "synced", bb.reload.dcs_sync_status
    assert_equal trade.buyer_emd_reference, bb.last_dcs_reference
    assert_equal "synced", sb.reload.dcs_sync_status

    # Strict Idempotency: re-running orchestrator creates ZERO extra events and preserves EMD numbers
    assert_no_difference "DcsSyncEvent.count" do
      AirlineDcs::SettlementOrchestrator.sync_trade!(trade)
    end
  end

  test "Saga compensation automatically voids Buyer EMD-A and rolls back PNR allowances + voucher if seller DCS update fails" do
    AirlineConnector.create!(
      airline_code: "AF",
      airline_name: "Air France",
      provider: "sandbox",
      accounting_prefix: "057",
      auth_mode: "sandbox"
    )
    flight = create_flight(airline_code: "AF", airline_name: "Air France", flight_number: "AF718")
    seller = create_user(name: "Marie Fail")
    buyer  = create_user(name: "Pierre Fail")
    sb = create_booking(user: seller, flight: flight, pnr_code: "FAIL1S", base_allowance_kg: 23.0, current_allowance_kg: 23.0)
    bb = create_booking(user: buyer, flight: flight, pnr_code: "OKAY1B", base_allowance_kg: 23.0, current_allowance_kg: 23.0)

    # Create matched trade without auto-sync, then run orchestrator with an adapter that fails on step 2
    failing_adapter = AirlineDcs::SandboxAdapter.new(
      AirlineConnector.find_by!(airline_code: "AF"),
      fail_operation: :adjust_seller_allowance
    )

    OrderBookMatchingService.place_and_match!(
      flight: flight, booking: sb, user: seller,
      side: "sell", quantity_kg: 8, price_per_kg_cents: 700, payout_preference: "voucher",
      sync_dcs: false
    )
    result = OrderBookMatchingService.place_and_match!(
      flight: flight, booking: bb, user: buyer,
      side: "buy", quantity_kg: 8, price_per_kg_cents: 750,
      sync_dcs: false
    )
    trade = result.trades.first

    # Before compensation: allowances were shifted and seller credited
    assert_in_delta 15.0, sb.reload.current_allowance_kg.to_f, 0.01
    assert_in_delta 31.0, bb.reload.current_allowance_kg.to_f, 0.01
    assert_operator seller.reload.voucher_balance_cents, :>, 0

    AirlineDcs::SettlementOrchestrator.new(trade, adapter: failing_adapter).call!

    trade.reload
    assert_equal "compensated", trade.dcs_sync_status
    assert_equal %w[issue_buyer_emd_a adjust_seller_allowance void_buyer_emd_a],
                 trade.dcs_sync_events.order(:id).pluck(:operation)
    assert_equal "compensated", trade.dcs_sync_events.find_by!(operation: "void_buyer_emd_a").status

    # Both PNRs and seller voucher wallet rolled back atomically to pre-trade state
    assert_in_delta 23.0, sb.reload.current_allowance_kg.to_f, 0.01
    assert_in_delta 23.0, bb.reload.current_allowance_kg.to_f, 0.01
    assert_equal 0, seller.reload.voucher_balance_cents
    assert_equal "attention_required", sb.dcs_sync_status
  end

  test "enterprise protocol adapters build standards-compliant IATA NDC, Navitaire REST, and HMAC Webhook payloads" do
    flight = create_flight(airline_code: "TS", airline_name: "Air Transat", flight_number: "TS111")
    seller = create_user
    buyer  = create_user
    sb = create_booking(user: seller, flight: flight, pnr_code: "TS111S")
    bb = create_booking(user: buyer, flight: flight, pnr_code: "TS111B")
    OrderBookMatchingService.place_and_match!(flight: flight, booking: sb, user: seller, side: "sell", quantity_kg: 6, price_per_kg_cents: 700, sync_dcs: false)
    trade = OrderBookMatchingService.place_and_match!(flight: flight, booking: bb, user: buyer, side: "buy", quantity_kg: 6, price_per_kg_cents: 750, sync_dcs: false).trades.first

    ndc_connector = AirlineConnector.new(airline_code: "AF", airline_name: "Air France", provider: "iata_ndc", accounting_prefix: "057", api_base_url: "https://ndc.airfrance.example/v21.3", auth_mode: "oauth2_mtls")
    ndc_payload = AirlineDcs::IataNdcAdapter.new(ndc_connector).build_buyer_emd_payload(trade: trade, booking: bb)
    assert_equal "IATA_OrderChangeRQ", ndc_payload.dig(:messageType)
    assert_equal "C", ndc_payload.dig(:service, :rfic)
    assert_equal "0GO", ndc_payload.dig(:service, :rfisc)
    assert_equal "XBAG", ndc_payload.dig(:service, :ssrCode)
    assert_equal "TS111B", ndc_payload.dig(:order, :pnrCode)

    nav_connector = AirlineConnector.new(airline_code: "TS", airline_name: "Air Transat", provider: "navitaire_rest", accounting_prefix: "649", api_base_url: "https://nsk.transat.example/api/nsk", auth_mode: "oauth2_client_credentials")
    nav_payload = AirlineDcs::NavitaireRestAdapter.new(nav_connector).build_buyer_emd_payload(trade: trade, booking: bb)
    assert_equal "XBAG", nav_payload[:ssrCode]
    assert_equal 6, nav_payload[:weightDeltaKg]
    assert_equal "TS111B", nav_payload[:recordLocator]

    wh_connector = AirlineConnector.new(airline_code: "AT", airline_name: "Royal Air Maroc", provider: "webhook_rest", accounting_prefix: "147", api_base_url: "https://gw.ram.example/baggage", auth_mode: "hmac_bearer")
    wh_adapter = AirlineDcs::WebhookRestAdapter.new(wh_connector)
    sig = wh_adapter.compute_signature(timestamp: "1700000000", body: '{"test":true}', secret: "super-secret")
    assert_match(/\Asha256=[0-9a-f]{64}\z/, sig)
  end
end

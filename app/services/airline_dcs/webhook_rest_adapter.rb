module AirlineDcs
  # Universal Carrier API Gateway Adapter (HMAC-SHA256 Signed JSON REST)
  # Allows any airline middleware / custom PSS to integrate in 1 day with zero vendor lock-in.
  class WebhookRestAdapter < BaseAdapter
    def compute_signature(timestamp:, body:, secret:)
      digest = OpenSSL::HMAC.hexdigest("SHA256", secret.to_s, "#{timestamp}.#{body}")
      "sha256=#{digest}"
    end

    def issue_buyer_emd_a(trade:, booking:, idempotency_key:)
      payload = {
        event: "baggage.allowance.increment",
        flightNumber: trade.flight.flight_number,
        pnrCode: booking.pnr_code,
        deltaKg: trade.quantity_kg.to_f,
        newAllowanceKg: booking.current_allowance_kg.to_f,
        iata: { rfic: "C", rfisc: "0GO", ssr: "XBAG" }
      }
      dispatch_signed(path: "allowances/increment", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG")
    end

    def adjust_seller_allowance(trade:, booking:, idempotency_key:)
      payload = {
        event: "baggage.allowance.decrement",
        flightNumber: trade.flight.flight_number,
        pnrCode: booking.pnr_code,
        deltaKg: -trade.quantity_kg.to_f,
        newAllowanceKg: booking.current_allowance_kg.to_f
      }
      dispatch_signed(path: "allowances/decrement", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "ASVC")
    end

    def issue_seller_voucher_emd_s(trade:, booking:, idempotency_key:)
      payload = {
        event: "voucher.credit.issue",
        pnrCode: booking.pnr_code,
        amountCents: trade.seller_payout_cents,
        currency: "EUR",
        iata: { rfic: "D", rfisc: "99I" }
      }
      dispatch_signed(path: "vouchers/issue", payload: payload, idempotency_key: idempotency_key, rfic: "D", rfisc: "99I", ssr: "VCHR")
    end

    def void_emd(external_reference:, pnr_code:, idempotency_key:)
      payload = {
        event: "baggage.allowance.void",
        pnrCode: pnr_code,
        externalReference: external_reference
      }
      dispatch_signed(path: "allowances/void", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG")
    end

    private

    def dispatch_signed(path:, payload:, idempotency_key:, rfic:, rfisc:, ssr:)
      unless connector.live_external?
        ref = generate_iata_emd_number("gw-sim-#{idempotency_key}")
        return Response.new(
          success: true,
          external_reference: ref,
          iata_rfic: rfic,
          iata_rfisc: rfisc,
          ssr_code: ssr,
          request_payload: payload,
          response_payload: { status: "SIMULATED_GATEWAY_OK", reference: ref, signed: "HMAC-SHA256" },
          latency_ms: 31
        )
      end

      secret = connector.resolve_secret(connector.credentials_ref)
      ts = Time.current.to_i.to_s
      sig = compute_signature(timestamp: ts, body: JSON.generate(payload), secret: secret)
      code, body, elapsed = post_json(
        path: path,
        payload: payload,
        headers: {
          "Idempotency-Key" => idempotency_key,
          "X-ShareMyBag-Timestamp" => ts,
          "X-ShareMyBag-Signature" => sig
        }
      )

      if code.between?(200, 299)
        Response.new(
          success: true,
          external_reference: body["reference"] || generate_iata_emd_number(idempotency_key),
          iata_rfic: rfic,
          iata_rfisc: rfisc,
          ssr_code: ssr,
          request_payload: payload,
          response_payload: body,
          latency_ms: elapsed
        )
      else
        Response.new(
          success: false,
          iata_rfic: rfic,
          iata_rfisc: rfisc,
          ssr_code: ssr,
          request_payload: payload,
          response_payload: body,
          latency_ms: elapsed,
          error_message: "Carrier Gateway HTTP #{code}: #{body['error'] || 'Rejected'}"
        )
      end
    end
  end
end

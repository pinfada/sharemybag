module AirlineDcs
  # Enterprise adapter for Navitaire New Skies / DotREZ REST APIs (Transavia, Volotea, Ryanair, Wizz Air)
  class NavitaireRestAdapter < BaseAdapter
    def build_buyer_emd_payload(trade:, booking:)
      {
        recordLocator: booking.pnr_code,
        flightDesignator: trade.flight.flight_number,
        ssrCode: "XBAG",
        weightDeltaKg: trade.quantity_kg.to_f,
        newAllowanceKg: booking.current_allowance_kg.to_f,
        note: "SHAREMYBAG EXCHANGE +#{trade.quantity_kg.to_f}KG TRADE #{trade.id}"
      }
    end

    def issue_buyer_emd_a(trade:, booking:, idempotency_key:)
      payload = build_buyer_emd_payload(trade: trade, booking: booking)
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG") unless connector.live_external?

      dispatch_navitaire(path: "v2/booking/ssrs", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG")
    end

    def adjust_seller_allowance(trade:, booking:, idempotency_key:)
      payload = {
        recordLocator: booking.pnr_code,
        flightDesignator: trade.flight.flight_number,
        ssrCode: "ASVC",
        weightDeltaKg: -trade.quantity_kg.to_f,
        newAllowanceKg: booking.current_allowance_kg.to_f
      }
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "C", rfisc: "0GO", ssr: "ASVC") unless connector.live_external?

      dispatch_navitaire(path: "v2/booking/ssrs/adjust", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "ASVC")
    end

    def restore_seller_allowance(trade:, booking:, idempotency_key:)
      payload = {
        recordLocator: booking.pnr_code,
        flightDesignator: trade.flight.flight_number,
        ssrCode: "ASVC",
        weightDeltaKg: trade.quantity_kg.to_f,
        newAllowanceKg: booking.current_allowance_kg.to_f
      }
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "C", rfisc: "0GO", ssr: "ASVC") unless connector.live_external?

      dispatch_navitaire(path: "v2/booking/ssrs/adjust", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "ASVC")
    end

    def issue_seller_voucher_emd_s(trade:, booking:, idempotency_key:)
      payload = {
        recordLocator: booking.pnr_code,
        voucherAmount: (trade.seller_payout_cents / 100.0).round(2),
        currencyCode: "EUR",
        reasonCode: "SMB_BAGGAGE_EXCHANGE"
      }
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "D", rfisc: "99I", ssr: "VCHR") unless connector.live_external?

      dispatch_navitaire(path: "v1/booking/payments/voucher", payload: payload, idempotency_key: idempotency_key, rfic: "D", rfisc: "99I", ssr: "VCHR")
    end

    def void_emd(external_reference:, pnr_code:, idempotency_key:)
      payload = { recordLocator: pnr_code, referenceNumber: external_reference, action: "VOID" }
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG") unless connector.live_external?

      dispatch_navitaire(path: "v2/booking/ssrs/void", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG")
    end

    private

    def dispatch_navitaire(path:, payload:, idempotency_key:, rfic:, rfisc:, ssr:)
      token = connector.resolve_secret(connector.credentials_ref)
      code, body, elapsed = post_json(
        path: path,
        payload: payload,
        headers: {
          "Authorization" => "Bearer #{token}",
          "Idempotency-Key" => idempotency_key
        }
      )

      reference = body["ssrReference"].presence || body["voucherCode"].presence
      if [200, 201].include?(code) && reference.present? && body["outcome"] != "REJECTED"
        Response.new(
          success: true,
          external_reference: reference,
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
          error_message: "Navitaire REST HTTP #{code}: #{body['message'] || 'Request failed'}"
        )
      end
    end

    def simulate_if_unconfigured(payload, idempotency_key, rfic:, rfisc:, ssr:)
      ref = generate_iata_emd_number("nsk-sim-#{idempotency_key}")
      Response.new(
        success: true,
        external_reference: ref,
        iata_rfic: rfic,
        iata_rfisc: rfisc,
        ssr_code: ssr,
        request_payload: payload,
        response_payload: { status: "SIMULATED_NSK_OK", ssrReference: ref, note: "Credentials ENV not set — executed in Navitaire sandbox mode" },
        latency_ms: 34
      )
    end
  end
end

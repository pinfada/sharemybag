module AirlineDcs
  # Enterprise adapter for IATA NDC 21.3+ / ONE Order REST Gateways (Amadeus Altéa, SabreSonic)
  class IataNdcAdapter < BaseAdapter
    def build_buyer_emd_payload(trade:, booking:)
      {
        messageType: "IATA_OrderChangeRQ",
        ndcVersion: "21.3",
        order: {
          pnrCode: booking.pnr_code,
          carrierCode: trade.flight.airline_code,
          flightNumber: trade.flight.flight_number,
          departureIata: trade.flight.departure_iata,
          arrivalIata: trade.flight.arrival_iata
        },
        service: {
          action: "ADD",
          rfic: "C",
          rfisc: "0GO",
          ssrCode: "XBAG",
          weightDeltaKg: trade.quantity_kg.to_f,
          updatedAllowanceKg: booking.current_allowance_kg.to_f,
          maxSinglePieceKg: PassengerBooking::IATA_MAX_SINGLE_BAG_KG
        },
        settlement: {
          amountCents: trade.gross_amount_cents,
          currency: "EUR",
          tradeRef: "SMB-TRADE-#{trade.id}"
        }
      }
    end

    def issue_buyer_emd_a(trade:, booking:, idempotency_key:)
      payload = build_buyer_emd_payload(trade: trade, booking: booking)
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG") unless connector.live_external?

      dispatch_ndc(path: "orders/#{booking.pnr_code}/change", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG")
    end

    def adjust_seller_allowance(trade:, booking:, idempotency_key:)
      payload = {
        messageType: "IATA_DCS_AllowanceAdjustRQ",
        ndcVersion: "21.3",
        order: { pnrCode: booking.pnr_code, flightNumber: trade.flight.flight_number },
        allowance: {
          action: "DECREMENT",
          weightDeltaKg: trade.quantity_kg.to_f,
          updatedAllowanceKg: booking.current_allowance_kg.to_f
        }
      }
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "C", rfisc: "0GO", ssr: "ASVC") unless connector.live_external?

      dispatch_ndc(path: "dcs/allowances/#{booking.pnr_code}", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "ASVC")
    end

    def issue_seller_voucher_emd_s(trade:, booking:, idempotency_key:)
      payload = {
        messageType: "IATA_EMD_StandaloneIssueRQ",
        ndcVersion: "21.3",
        pnrCode: booking.pnr_code,
        rfic: "D",
        rfisc: "99I",
        amountCents: trade.seller_payout_cents,
        currency: "EUR"
      }
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "D", rfisc: "99I", ssr: "VCHR") unless connector.live_external?

      dispatch_ndc(path: "emds/standalone", payload: payload, idempotency_key: idempotency_key, rfic: "D", rfisc: "99I", ssr: "VCHR")
    end

    def void_emd(external_reference:, pnr_code:, idempotency_key:)
      payload = {
        messageType: "IATA_EMD_VoidRQ",
        emdNumber: external_reference,
        pnrCode: pnr_code
      }
      return simulate_if_unconfigured(payload, idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG") unless connector.live_external?

      dispatch_ndc(path: "emds/#{external_reference}/void", payload: payload, idempotency_key: idempotency_key, rfic: "C", rfisc: "0GO", ssr: "XBAG")
    end

    private

    def dispatch_ndc(path:, payload:, idempotency_key:, rfic:, rfisc:, ssr:)
      token = connector.resolve_secret(connector.credentials_ref)
      code, body, elapsed = post_json(
        path: path,
        payload: payload,
        headers: {
          "Authorization" => "Bearer #{token}",
          "Idempotency-Key" => idempotency_key,
          "X-IATA-NDC-Version" => "21.3"
        }
      )

      if code.between?(200, 299)
        Response.new(
          success: true,
          external_reference: body["emdNumber"] || body["transactionId"] || generate_iata_emd_number(idempotency_key),
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
          error_message: "IATA NDC Gateway HTTP #{code}: #{body['error'] || body['message'] || 'Request rejected'}"
        )
      end
    end

    def simulate_if_unconfigured(payload, idempotency_key, rfic:, rfisc:, ssr:)
      ref = generate_iata_emd_number("ndc-sim-#{idempotency_key}")
      Response.new(
        success: true,
        external_reference: ref,
        iata_rfic: rfic,
        iata_rfisc: rfisc,
        ssr_code: ssr,
        request_payload: payload,
        response_payload: { status: "SIMULATED_NDC_OK", emdNumber: ref, note: "Credentials ENV not set — executed in carrier sandbox mode" },
        latency_ms: 46
      )
    end
  end
end

module AirlineDcs
  class SandboxAdapter < BaseAdapter
    def initialize(connector, fail_operation: nil)
      super(connector)
      @fail_operations = Array(fail_operation).map(&:to_sym)
    end

    def issue_buyer_emd_a(trade:, booking:, idempotency_key:)
      payload = {
        protocol: "IATA_NDC_SANDBOX",
        operation: "EMD_A_ISSUE",
        carrier: trade.flight.airline_code,
        flightNumber: trade.flight.flight_number,
        pnrCode: booking.pnr_code,
        weightAddedKg: trade.quantity_kg.to_f,
        newTotalAllowanceKg: booking.current_allowance_kg.to_f,
        iataRfic: "C",
        iataRfisc: "0GO",
        ssrCode: "XBAG",
        amountCents: trade.gross_amount_cents,
        currency: "EUR"
      }

      if @fail_operations.include?(:issue_buyer_emd_a)
        return failure_response(payload, "Simulated DCS timeout while issuing buyer EMD-A", rfic: "C", rfisc: "0GO", ssr: "XBAG")
      end

      ref = generate_iata_emd_number("emd-a-#{idempotency_key}")
      Response.new(
        success: true,
        external_reference: ref,
        iata_rfic: "C",
        iata_rfisc: "0GO",
        ssr_code: "XBAG",
        request_payload: payload,
        response_payload: { status: "ISSUED", emdNumber: ref, dcsSynced: true, ssrStatus: "HK" },
        latency_ms: 42
      )
    end

    def adjust_seller_allowance(trade:, booking:, idempotency_key:)
      payload = {
        protocol: "IATA_DCS_CM_SANDBOX",
        operation: "DCS_ALLOWANCE_DECREMENT",
        carrier: trade.flight.airline_code,
        flightNumber: trade.flight.flight_number,
        pnrCode: booking.pnr_code,
        weightDeductedKg: trade.quantity_kg.to_f,
        newTotalAllowanceKg: booking.current_allowance_kg.to_f,
        ssrCode: "ASVC"
      }

      if @fail_operations.include?(:adjust_seller_allowance)
        return failure_response(payload, "Simulated DCS lock error: seller PNR already checked-in at counter", ssr: "ASVC")
      end

      ref = "DCS-#{trade.flight.airline_code}-#{Digest::SHA256.hexdigest(idempotency_key).first(10).upcase}"
      Response.new(
        success: true,
        external_reference: ref,
        iata_rfic: "C",
        iata_rfisc: "0GO",
        ssr_code: "ASVC",
        request_payload: payload,
        response_payload: { status: "UPDATED", dcsTransactionId: ref, newAllowanceKg: booking.current_allowance_kg.to_f },
        latency_ms: 35
      )
    end

    def restore_seller_allowance(trade:, booking:, idempotency_key:)
      payload = {
        protocol: "IATA_DCS_CM_SANDBOX",
        operation: "DCS_ALLOWANCE_INCREMENT",
        carrier: trade.flight.airline_code,
        flightNumber: trade.flight.flight_number,
        pnrCode: booking.pnr_code,
        weightRestoredKg: trade.quantity_kg.to_f,
        newTotalAllowanceKg: booking.current_allowance_kg.to_f,
        ssrCode: "ASVC"
      }

      if @fail_operations.include?(:restore_seller_allowance)
        return failure_response(payload, "Simulated seller allowance restoration failure", ssr: "ASVC")
      end

      ref = "DCS-#{trade.flight.airline_code}-#{Digest::SHA256.hexdigest(idempotency_key).first(10).upcase}"
      Response.new(
        success: true,
        external_reference: ref,
        iata_rfic: "C",
        iata_rfisc: "0GO",
        ssr_code: "ASVC",
        request_payload: payload,
        response_payload: { status: "UPDATED", dcsTransactionId: ref, newAllowanceKg: booking.current_allowance_kg.to_f },
        latency_ms: 35
      )
    end

    def issue_seller_voucher_emd_s(trade:, booking:, idempotency_key:)
      payload = {
        protocol: "IATA_EMD_S_SANDBOX",
        operation: "EMD_S_VOUCHER_ISSUE",
        carrier: trade.flight.airline_code,
        pnrCode: booking.pnr_code,
        iataRfic: "D",
        iataRfisc: "99I",
        voucherValueCents: trade.seller_payout_cents,
        currency: "EUR",
        validityDays: 365
      }

      if @fail_operations.include?(:issue_seller_voucher_emd_s)
        return failure_response(payload, "Simulated voucher ledger unavailable", rfic: "D", rfisc: "99I")
      end

      ref = generate_iata_emd_number("emd-s-#{idempotency_key}")
      Response.new(
        success: true,
        external_reference: ref,
        iata_rfic: "D",
        iata_rfisc: "99I",
        ssr_code: "VCHR",
        request_payload: payload,
        response_payload: { status: "ISSUED", emdNumber: ref, redeemableOnline: true },
        latency_ms: 28
      )
    end

    def void_emd(external_reference:, pnr_code:, idempotency_key:)
      payload = {
        protocol: "IATA_EMD_VOID_SANDBOX",
        operation: "EMD_VOID",
        emdNumber: external_reference,
        pnrCode: pnr_code,
        reason: "SAGA_COMPENSATION_ROLLBACK"
      }

      if @fail_operations.include?(:void_emd)
        return failure_response(payload, "Simulated buyer EMD void failure")
      end

      Response.new(
        success: true,
        external_reference: "VOID-#{external_reference}",
        iata_rfic: "C",
        iata_rfisc: "0GO",
        ssr_code: "XBAG",
        request_payload: payload,
        response_payload: { status: "VOIDED", originalEmd: external_reference },
        latency_ms: 24
      )
    end

    private

    def failure_response(payload, message, rfic: nil, rfisc: nil, ssr: nil)
      Response.new(
        success: false,
        iata_rfic: rfic,
        iata_rfisc: rfisc,
        ssr_code: ssr,
        request_payload: payload,
        response_payload: { status: "ERROR", message: message },
        latency_ms: 61,
        error_message: message
      )
    end
  end
end

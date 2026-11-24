module AirlineDcs
  # Saga Orchestrator for atomic, idempotent IATA EMD / DCS synchronization.
  # Executes outside the order-book DB lock so external carrier API latency never stalls matching.
  class SettlementOrchestrator
    def self.sync_trade!(trade, adapter: nil)
      new(trade, adapter: adapter).call!
    end

    def initialize(trade, adapter: nil)
      @trade = trade
      @flight = trade.flight
      @connector = Registry.connector_for(@flight)
      @adapter = adapter || Registry.adapter_for(@connector)
    end

    def call!
      return @trade if @trade.dcs_sync_status == "synced"

      buyer_booking = @trade.buy_order.passenger_booking
      seller_booking = @trade.sell_order.passenger_booking

      # Step 1: Issue Buyer EMD-A (+kg, RFIC C / RFISC 0GO / SSR XBAG)
      buyer_event = execute_idempotent_step!(
        operation: "issue_buyer_emd_a",
        pnr_code: buyer_booking.pnr_code
      ) do |key|
        @adapter.issue_buyer_emd_a(trade: @trade, booking: buyer_booking, idempotency_key: key)
      end

      unless buyer_event.status == "synced"
        rollback_local_settlement!(buyer_booking, seller_booking, trade_status: "failed")
        return @trade
      end

      # Step 2: Decrement Seller DCS Allowance (-kg in DCS Customer Management)
      seller_adj_event = execute_idempotent_step!(
        operation: "adjust_seller_allowance",
        pnr_code: seller_booking.pnr_code
      ) do |key|
        @adapter.adjust_seller_allowance(trade: @trade, booking: seller_booking, idempotency_key: key)
      end

      unless seller_adj_event.status == "synced"
        compensate_buyer_emd!(buyer_event, buyer_booking, seller_booking)
        return @trade
      end

      # Step 3 (when voucher payout): Issue Seller Voucher EMD-S (RFIC D / RFISC 99I)
      voucher_ref = nil
      if @trade.payout_type == "voucher"
        voucher_event = execute_idempotent_step!(
          operation: "issue_seller_voucher_emd_s",
          pnr_code: seller_booking.pnr_code
        ) do |key|
          @adapter.issue_seller_voucher_emd_s(trade: @trade, booking: seller_booking, idempotency_key: key)
        end

        unless voucher_event.status == "synced"
          compensate_buyer_emd!(buyer_event, buyer_booking, seller_booking)
          return @trade
        end
        voucher_ref = voucher_event.external_reference
      end

      now = Time.current
      ActiveRecord::Base.transaction do
        @trade.update!(
          dcs_sync_status: "synced",
          buyer_emd_reference: buyer_event.external_reference,
          seller_voucher_emd_reference: voucher_ref,
          dcs_synced_at: now
        )
        buyer_booking.update!(
          dcs_sync_status: "synced",
          last_dcs_reference: buyer_event.external_reference,
          last_dcs_synced_at: now
        )
        seller_booking.update!(
          dcs_sync_status: "synced",
          last_dcs_reference: voucher_ref || seller_adj_event.external_reference,
          last_dcs_synced_at: now
        )
      end

      @trade
    end

    private

    def execute_idempotent_step!(operation:, pnr_code:)
      key = "smb-trade-#{@trade.id}-#{operation}"
      existing = DcsSyncEvent.find_by(idempotency_key: key)
      return existing if existing&.status == "synced"

      event = existing || DcsSyncEvent.create!(
        kilo_trade: @trade,
        airline_connector: @connector,
        idempotency_key: key,
        operation: operation,
        pnr_code: pnr_code,
        status: "pending"
      )

      response = yield(key)
      event.update!(
        status: response.success? ? "synced" : "failed",
        external_reference: response.external_reference,
        iata_rfic: response.iata_rfic,
        iata_rfisc: response.iata_rfisc,
        ssr_code: response.ssr_code,
        request_payload: response.request_payload || {},
        response_payload: response.response_payload || {},
        error_message: response.error_message,
        latency_ms: response.latency_ms,
        attempts: event.attempts + 1,
        synced_at: response.success? ? Time.current : nil
      )
      event
    end

    def compensate_buyer_emd!(buyer_event, buyer_booking, seller_booking)
      void_key = "smb-trade-#{@trade.id}-void_buyer_emd_a"
      void_response = @adapter.void_emd(
        external_reference: buyer_event.external_reference,
        pnr_code: buyer_booking.pnr_code,
        idempotency_key: void_key
      )

      DcsSyncEvent.create!(
        kilo_trade: @trade,
        airline_connector: @connector,
        idempotency_key: void_key,
        operation: "void_buyer_emd_a",
        pnr_code: buyer_booking.pnr_code,
        status: void_response.success? ? "compensated" : "failed",
        external_reference: void_response.external_reference,
        iata_rfic: void_response.iata_rfic,
        iata_rfisc: void_response.iata_rfisc,
        ssr_code: void_response.ssr_code,
        request_payload: void_response.request_payload || {},
        response_payload: void_response.response_payload || {},
        error_message: void_response.error_message,
        latency_ms: void_response.latency_ms,
        attempts: 1,
        synced_at: Time.current
      )

      rollback_local_settlement!(buyer_booking, seller_booking, trade_status: "compensated")
    end

    def rollback_local_settlement!(buyer_booking, seller_booking, trade_status:)
      ActiveRecord::Base.transaction do
        buyer_booking.lock!
        seller_booking.lock!

        qty = @trade.quantity_kg.to_d
        buyer_booking.update!(
          current_allowance_kg: [buyer_booking.current_allowance_kg.to_d - qty, 0.to_d].max,
          dcs_sync_status: "attention_required"
        )
        seller_booking.update!(
          current_allowance_kg: [seller_booking.current_allowance_kg.to_d + qty, seller_booking.max_allowance_kg.to_d].min,
          dcs_sync_status: "attention_required"
        )

        if @trade.payout_type == "voucher"
          seller_user = @trade.seller.lock!
          seller_user.update!(
            voucher_balance_cents: [seller_user.voucher_balance_cents - @trade.seller_payout_cents, 0].max
          )
        end

        @trade.update!(dcs_sync_status: trade_status)
      end
    end
  end
end

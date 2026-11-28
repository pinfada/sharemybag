module AirlineDcs
  class SettlementOrchestrator
    LOCK_NAMESPACE = 0x534D42

    def self.sync_trade!(trade, adapter: nil)
      new(trade, adapter: adapter).call!
    end

    def initialize(trade, adapter: nil)
      @trade = trade
      @flight = trade.flight
      @connector = trade.dcs_sync_events.order(:id).first&.airline_connector || Registry.connector_for(@flight)
      @adapter = adapter || Registry.adapter_for(@connector)
    end

    def call!
      # Serialize absolute allowance updates without holding the matching row lock
      # during carrier requests. Persist each carrier acknowledgement before proceeding.
      KiloTrade.connection_pool.with_connection do |connection|
        lock = "#{LOCK_NAMESPACE}, #{@flight.id.to_i}"
        connection.execute("SELECT pg_advisory_lock(#{lock})")
        begin
          settle!
        ensure
          connection.execute("SELECT pg_advisory_unlock(#{lock})")
        end
      end
      @trade
    end

    private

    def settle!
      @trade.reload
      return unless KiloTrade::UNRESOLVED_STATUSES.include?(@trade.dcs_sync_status)

      # Finish earlier trades first so a retry sends the same absolute allowances.
      return if @flight.kilo_trades.where(dcs_sync_status: KiloTrade::UNRESOLVED_STATUSES)
                       .where("id < ?", @trade.id).exists?

      unless @connector.active? && (@connector.live_external? || @connector.simulated_settlement?)
        @trade.update!(dcs_sync_status: "attention_required") unless @trade.dcs_sync_status == "compensating"
        return
      end

      @buyer_booking = @trade.buy_order.passenger_booking
      @seller_booking = @trade.sell_order.passenger_booking

      return compensate! if @trade.dcs_sync_status == "compensating"

      buyer_event = execute_step!("issue_buyer_emd_a", @buyer_booking) do |key|
        @adapter.issue_buyer_emd_a(trade: @trade, booking: projected_booking(@buyer_booking, @trade.quantity_kg), idempotency_key: key)
      end
      return handle_failure!(buyer_event) unless buyer_event.status == "synced"

      seller_event = execute_step!("adjust_seller_allowance", @seller_booking) do |key|
        @adapter.adjust_seller_allowance(trade: @trade, booking: projected_booking(@seller_booking, -@trade.quantity_kg), idempotency_key: key)
      end
      return handle_failure!(seller_event) unless seller_event.status == "synced"

      voucher_event = nil
      if @trade.payout_type == "voucher"
        voucher_event = execute_step!("issue_seller_voucher_emd_s", @seller_booking) do |key|
          @adapter.issue_seller_voucher_emd_s(trade: @trade, booking: @seller_booking, idempotency_key: key)
        end
        return handle_failure!(voucher_event) unless voucher_event.status == "synced"
      end

      finalize!(buyer_event, seller_event, voucher_event)
    end

    def projected_booking(booking, delta)
      return booking unless @trade.deferred_settlement?

      booking.dup.tap { |projection| projection.current_allowance_kg += delta }
    end

    def handle_failure!(event)
      # A live timeout or unclassified error may have applied the command.
      # Retry with the same idempotency key until the carrier confirms its outcome.
      if @connector.live_external? && event.response_payload["outcome"] != "REJECTED"
        @trade.update!(dcs_sync_status: "attention_required")
        return
      end

      @trade.update!(dcs_sync_status: "compensating")
      compensate!
    end

    def compensate!
      buyer_event = @trade.dcs_sync_events.find_by(operation: "issue_buyer_emd_a", status: "synced")
      seller_event = @trade.dcs_sync_events.find_by(operation: "adjust_seller_allowance", status: "synced")

      if seller_event
        restored = execute_step!("restore_seller_allowance", @seller_booking, success_status: "compensated") do |key|
          booking = @seller_booking.dup
          booking.current_allowance_kg += @trade.quantity_kg unless @trade.deferred_settlement?
          @adapter.restore_seller_allowance(trade: @trade, booking: booking, idempotency_key: key)
        end
      end

      if buyer_event
        voided = execute_step!("void_buyer_emd_a", @buyer_booking, success_status: "compensated") do |key|
          @adapter.void_emd(external_reference: buyer_event.external_reference, pnr_code: @buyer_booking.pnr_code, idempotency_key: key)
        end
      end

      # Keep the reservation and compensation state for retry while either reversal is unresolved.
      return if [restored, voided].compact.any? { |event| event.status != "compensated" }

      @flight.with_lock do
        rollback_legacy_transfer! unless @trade.deferred_settlement?
        [@trade.buy_order, @trade.sell_order].each do |order|
          order.reload
          next if order.status == "cancelled"

          remaining = order.remaining_kg + @trade.quantity_kg
          status = remaining == order.quantity_kg ? "open" : "partially_filled"
          order.update!(remaining_kg: remaining, status: status)
        end
        @trade.update!(dcs_sync_status: buyer_event ? "compensated" : "failed")
      end
    end

    def execute_step!(operation, booking, success_status: "synced")
      key = "smb-trade-#{@trade.id}-#{operation}"
      event = @trade.dcs_sync_events.find_or_initialize_by(idempotency_key: key)
      return event if event.persisted? && event.status == success_status

      if event.new_record?
        event.assign_attributes(airline_connector: @connector, operation: operation, pnr_code: booking.pnr_code, status: "pending")
        event.save!
      end

      response = yield(key)
      event.with_lock do
        unless event.status == success_status
          event.update!(
            status: response.success? ? success_status : "failed",
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
        end
      end
      event
    end

    def finalize!(buyer_event, seller_event, voucher_event)
      @flight.with_lock do
        now = Time.current
        @buyer_booking.reload
        @seller_booking.reload

        if @trade.deferred_settlement?
          @buyer_booking.current_allowance_kg += @trade.quantity_kg
          @seller_booking.current_allowance_kg -= @trade.quantity_kg
          if voucher_event
            seller = @trade.seller.lock!
            seller.update!(voucher_balance_cents: seller.voucher_balance_cents + @trade.seller_payout_cents)
          end
        end

        @buyer_booking.update!(dcs_sync_status: "synced", last_dcs_reference: buyer_event.external_reference, last_dcs_synced_at: now)
        @seller_booking.update!(dcs_sync_status: "synced", last_dcs_reference: voucher_event&.external_reference || seller_event.external_reference, last_dcs_synced_at: now)
        @trade.update!(
          dcs_sync_status: "synced",
          buyer_emd_reference: buyer_event.external_reference,
          seller_voucher_emd_reference: voucher_event&.external_reference,
          dcs_synced_at: now
        )
        notify_counterparties! if @trade.deferred_settlement?
      end
    end

    def rollback_legacy_transfer!
      @buyer_booking.reload
      @seller_booking.reload
      @buyer_booking.update!(current_allowance_kg: @buyer_booking.current_allowance_kg - @trade.quantity_kg, dcs_sync_status: "attention_required")
      @seller_booking.update!(current_allowance_kg: @seller_booking.current_allowance_kg + @trade.quantity_kg, dcs_sync_status: "attention_required")
      if @trade.payout_type == "voucher"
        seller = @trade.seller.lock!
        seller.update!(voucher_balance_cents: [seller.voucher_balance_cents - @trade.seller_payout_cents, 0].max)
      end
    end

    def notify_counterparties!
      qty = format("%g kg", @trade.quantity_kg)
      price = format("€%.2f/kg", @trade.execution_price_per_kg_cents / 100.0)
      Notification.notify(@trade.buyer, @flight, "trade_bought",
                          "Bought #{qty} on #{@flight.flight_number} at #{price}. PNR #{@buyer_booking.pnr_code} confirmed at #{@buyer_booking.current_allowance_kg.to_f} kg.")
      payout = format("€%.2f", @trade.seller_payout_cents / 100.0)
      payout_label = @trade.payout_type == "voucher" ? "#{payout} airline flight voucher credited" : "#{payout} cash payout due"
      Notification.notify(@trade.seller, @flight, "trade_sold",
                          "Sold #{qty} on #{@flight.flight_number} at #{price} (#{payout_label}). PNR #{@seller_booking.pnr_code} confirmed at #{@seller_booking.current_allowance_kg.to_f} kg.")
    end
  end
end

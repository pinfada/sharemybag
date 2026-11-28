require "openssl"

module Api
  module V1
    class DcsWebhooksController < ActionController::API
      MAX_CLOCK_SKEW_SECONDS = 300

      before_action :load_connector
      before_action :verify_hmac_signature!

      def create
        payload = JSON.parse(@raw_body)
        event_type = payload["event"].to_s

        case event_type
        when "flight.weight_balance_locked"
          handle_weight_balance_locked(payload)
        when "flight.equipment_swap"
          handle_equipment_swap(payload)
        when "emd.confirmed"
          handle_emd_confirmed(payload)
        else
          render json: { error: "Unsupported event type" }, status: :unprocessable_entity
        end
      rescue JSON::ParserError
        render json: { error: "Invalid JSON payload" }, status: :bad_request
      end

      private

      def load_connector
        @connector = AirlineConnector.active.find_by(airline_code: params[:airline_code].to_s.upcase)
        render json: { error: "Unknown airline connector" }, status: :not_found unless @connector
      end

      def verify_hmac_signature!
        @raw_body = request.raw_post.to_s
        secret = @connector.webhook_signing_secret
        timestamp = request.headers["X-ShareMyBag-Timestamp"].to_s
        signature = request.headers["X-ShareMyBag-Signature"].to_s

        if secret.blank? || timestamp.blank? || signature.blank?
          return render json: { error: "Missing webhook authentication headers" }, status: :unauthorized
        end

        if (Time.current.to_i - timestamp.to_i).abs > MAX_CLOCK_SKEW_SECONDS
          return render json: { error: "Webhook timestamp outside replay window" }, status: :unauthorized
        end

        expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{timestamp}.#{@raw_body}")}"
        unless ActiveSupport::SecurityUtils.secure_compare(expected, signature)
          render json: { error: "Invalid HMAC signature" }, status: :unauthorized
        end
      end

      def handle_weight_balance_locked(payload)
        flight = Flight.find_by(airline_code: @connector.airline_code, flight_number: payload["flight_number"].to_s.upcase)
        return render json: { error: "Flight not found" }, status: :not_found unless flight

        flight.update!(status: "closed")
        render json: { status: "ok", flight_number: flight.flight_number, exchange_status: flight.status }, status: :ok
      end

      def handle_equipment_swap(payload)
        flight = Flight.find_by(airline_code: @connector.airline_code, flight_number: payload["flight_number"].to_s.upcase)
        new_aircraft = AircraftType.find_by(code: payload["new_aircraft_code"].to_s)
        return render json: { error: "Flight or aircraft type not found" }, status: :not_found unless flight && new_aircraft

        over_cap = flight.current_total_baggage_kg > new_aircraft.max_baggage_payload_kg.to_f
        new_status = over_cap ? "closed" : flight.status

        # Use update_columns for aircraft swap when booked load exceeds smaller replacement aircraft
        # so the exchange immediately freezes trading instead of raising a validation error.
        flight.update_columns(
          aircraft_type_id: new_aircraft.id,
          status: new_status,
          updated_at: Time.current
        )

        render json: {
          status: "ok",
          flight_number: flight.flight_number,
          aircraft_code: new_aircraft.code,
          exchange_status: new_status,
          payload_exceeded_freeze: over_cap
        }, status: :ok
      end

      def handle_emd_confirmed(payload)
        event = @connector.dcs_sync_events.find_by(
          idempotency_key: payload["idempotency_key"].to_s,
          operation: %w[issue_buyer_emd_a issue_seller_voucher_emd_s]
        )
        return render json: { error: "Sync event not found" }, status: :not_found unless event

        event.with_lock do
          if event.status != "synced" && %w[pending attention_required].include?(event.kilo_trade.dcs_sync_status)
            reference = payload["emd_number"].presence || event.external_reference
            return render json: { error: "Missing EMD reference" }, status: :unprocessable_entity if reference.blank?

            event.update!(status: "synced", external_reference: reference, synced_at: Time.current)
          end
        end
        render json: { status: "ok", idempotency_key: event.idempotency_key }, status: :ok
      end
    end
  end
end

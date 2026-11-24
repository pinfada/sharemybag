module AirlineDcs
  Response = Struct.new(
    :success,
    :external_reference,
    :iata_rfic,
    :iata_rfisc,
    :ssr_code,
    :request_payload,
    :response_payload,
    :latency_ms,
    :error_message,
    keyword_init: true
  ) do
    def success?
      !!success
    end
  end
end

module AirlineDcs
  class Registry
    ADAPTER_MAP = {
      "sandbox"        => AirlineDcs::SandboxAdapter,
      "iata_ndc"       => AirlineDcs::IataNdcAdapter,
      "navitaire_rest" => AirlineDcs::NavitaireRestAdapter,
      "webhook_rest"   => AirlineDcs::WebhookRestAdapter
    }.freeze

    ACCOUNTING_PREFIXES = {
      "AF" => "057",
      "BA" => "125",
      "TS" => "649",
      "AT" => "147",
      "TU" => "199",
      "SN" => "082"
    }.freeze

    def self.connector_for(flight)
      AirlineConnector.find_by(airline_code: flight.airline_code.to_s.upcase) ||
        AirlineConnector.create!(
          airline_code: flight.airline_code.to_s.upcase,
          airline_name: flight.airline_name,
          provider: "sandbox",
          accounting_prefix: ACCOUNTING_PREFIXES[flight.airline_code.to_s.upcase] || "057",
          auth_mode: "sandbox",
          active: true
        )
    end

    def self.adapter_for(connector)
      klass = ADAPTER_MAP[connector.provider] || AirlineDcs::SandboxAdapter
      klass.new(connector)
    end
  end
end

class IntegrationsController < ApplicationController
  def index
    @connectors = AirlineConnector.order(:airline_code)
    @recent_events = DcsSyncEvent.includes(:airline_connector, kilo_trade: :flight)
                                 .recent
                                 .limit(20)
    @synced_count = DcsSyncEvent.where(status: "synced").count
    @compensated_count = DcsSyncEvent.where(status: "compensated").count
    @avg_latency_ms = DcsSyncEvent.where.not(latency_ms: nil).average(:latency_ms)&.round || 0
    @latest_emd_event = @recent_events.find { |e| e.operation == "issue_buyer_emd_a" }
  end
end

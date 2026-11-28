namespace :dcs do
  desc "Retry unresolved carrier settlement and compensation (optional FLIGHT_ID)"
  task retry_settlements: :environment do
    trades = KiloTrade.where(dcs_sync_status: KiloTrade::UNRESOLVED_STATUSES)
    trades = trades.where(flight_id: ENV.fetch("FLIGHT_ID")) if ENV["FLIGHT_ID"].present?

    trades.find_each do |trade|
      AirlineDcs::SettlementOrchestrator.sync_trade!(trade)
      puts "Trade #{trade.id}: #{trade.reload.dcs_sync_status}"
    end
  end
end

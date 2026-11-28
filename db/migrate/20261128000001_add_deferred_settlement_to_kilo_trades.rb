class AddDeferredSettlementToKiloTrades < ActiveRecord::Migration[7.0]
  def change
    add_column :kilo_trades, :deferred_settlement, :boolean, default: false, null: false
  end
end

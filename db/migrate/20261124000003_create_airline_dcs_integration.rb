class CreateAirlineDcsIntegration < ActiveRecord::Migration[7.0]
  def change
    create_table :airline_connectors do |t|
      t.string  :airline_code, null: false
      t.string  :airline_name, null: false
      t.string  :provider, null: false, default: "sandbox"
      t.string  :accounting_prefix, null: false, default: "057"
      t.string  :api_base_url
      t.string  :auth_mode, null: false, default: "oauth2_mtls"
      t.string  :credentials_ref
      t.string  :webhook_signing_secret_ref
      t.integer :timeout_seconds, null: false, default: 5
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :airline_connectors, :airline_code, unique: true

    create_table :dcs_sync_events do |t|
      t.references :kilo_trade, null: false, foreign_key: true
      t.references :airline_connector, null: false, foreign_key: true
      t.string     :idempotency_key, null: false
      t.string     :operation, null: false
      t.string     :pnr_code, null: false
      t.string     :status, null: false, default: "pending"
      t.string     :external_reference
      t.string     :iata_rfic
      t.string     :iata_rfisc
      t.string     :ssr_code
      t.jsonb      :request_payload, null: false, default: {}
      t.jsonb      :response_payload, null: false, default: {}
      t.string     :error_message
      t.integer    :latency_ms
      t.integer    :attempts, null: false, default: 0
      t.datetime   :synced_at

      t.timestamps
    end
    add_index :dcs_sync_events, :idempotency_key, unique: true
    add_index :dcs_sync_events, [:kilo_trade_id, :operation]
    add_index :dcs_sync_events, :status

    add_column :kilo_trades, :dcs_sync_status, :string, null: false, default: "pending"
    add_column :kilo_trades, :buyer_emd_reference, :string
    add_column :kilo_trades, :seller_voucher_emd_reference, :string
    add_column :kilo_trades, :dcs_synced_at, :datetime

    add_column :passenger_bookings, :dcs_sync_status, :string, null: false, default: "synced"
    add_column :passenger_bookings, :last_dcs_reference, :string
    add_column :passenger_bookings, :last_dcs_synced_at, :datetime
  end
end

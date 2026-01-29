class CreateHandlingEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :handling_events do |t|
      t.references :shipment_tracking, null: false, foreign_key: true, index: true
      t.references :actor, foreign_key: { to_table: :users }, index: true
      t.string :event_type, null: false # pickup, security_check, airport_checkin, loaded, unloaded, customs_cleared, in_transit, arrived, handoff, delivery
      t.string :location
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :photo_url
      t.text :notes
      t.string :signature_url # digital signature capture
      t.string :barcode_scanned
      t.string :seal_number # tamper-evident seal
      t.boolean :seal_intact
      t.string :content_hash, null: false # SHA256 of all event data for immutability
      t.string :previous_event_hash # chain hash linking to previous event
      t.jsonb :environmental_data, default: {} # temperature, humidity, shock
      t.string :device_id # tracking device identifier
      t.boolean :anomaly_detected, default: false
      t.text :anomaly_description
      t.timestamps
    end

    add_index :handling_events, :event_type
    add_index :handling_events, :content_hash, unique: true
    add_index :handling_events, [:shipment_tracking_id, :created_at], name: "idx_handling_events_tracking_timeline"
  end
end

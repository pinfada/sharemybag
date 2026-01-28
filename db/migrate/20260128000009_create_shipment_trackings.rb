class CreateShipmentTrackings < ActiveRecord::Migration[5.0]
  def change
    create_table :shipment_trackings do |t|
      t.references :shipping_request, foreign_key: true, null: false
      t.references :traveler, foreign_key: { to_table: :users }, null: false
      t.string :status, default: "created", null: false
      t.string :handover_code
      t.string :delivery_code
      t.string :handover_photo_url
      t.string :delivery_photo_url
      t.datetime :handed_over_at
      t.datetime :in_transit_at
      t.datetime :delivered_at
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :shipment_trackings, :status
    add_index :shipment_trackings, :handover_code, unique: true
    add_index :shipment_trackings, :delivery_code, unique: true
  end
end

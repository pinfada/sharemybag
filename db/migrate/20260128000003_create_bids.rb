class CreateBids < ActiveRecord::Migration[5.0]
  def change
    create_table :bids do |t|
      t.references :shipping_request, foreign_key: true, null: false
      t.references :traveler, foreign_key: { to_table: :users }, null: false
      t.references :kilo_offer, foreign_key: true
      t.decimal :price_per_kg_cents, precision: 10, scale: 0, null: false
      t.decimal :available_kg, precision: 8, scale: 2, null: false
      t.string :currency, default: "EUR", null: false
      t.date :travel_date, null: false
      t.string :flight_number
      t.string :status, default: "pending", null: false
      t.text :message

      t.timestamps
    end

    add_index :bids, :status
    add_index :bids, [:shipping_request_id, :traveler_id], unique: true
  end
end

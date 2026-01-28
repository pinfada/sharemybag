class CreateKiloOffers < ActiveRecord::Migration[5.0]
  def change
    create_table :kilo_offers do |t|
      t.references :traveler, foreign_key: { to_table: :users }, null: false
      t.references :vol, foreign_key: true
      t.string :departure_city, null: false
      t.string :departure_country, null: false
      t.string :arrival_city, null: false
      t.string :arrival_country, null: false
      t.date :travel_date, null: false
      t.decimal :available_kg, precision: 8, scale: 2, null: false
      t.decimal :price_per_kg_cents, precision: 10, scale: 0, null: false
      t.string :currency, default: "EUR", null: false
      t.string :status, default: "active", null: false
      t.text :accepted_items
      t.text :restrictions
      t.string :flight_number

      t.timestamps
    end

    add_index :kilo_offers, :status
    add_index :kilo_offers, [:departure_city, :arrival_city]
    add_index :kilo_offers, :travel_date
  end
end

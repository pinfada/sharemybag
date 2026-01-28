class CreateShippingRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :shipping_requests do |t|
      t.references :sender, foreign_key: { to_table: :users }, null: false
      t.string :title, null: false
      t.text :description
      t.decimal :weight_kg, precision: 8, scale: 2, null: false
      t.decimal :length_cm, precision: 8, scale: 2
      t.decimal :width_cm, precision: 8, scale: 2
      t.decimal :height_cm, precision: 8, scale: 2
      t.string :departure_city, null: false
      t.string :departure_country, null: false
      t.string :arrival_city, null: false
      t.string :arrival_country, null: false
      t.date :desired_date, null: false
      t.date :deadline_date
      t.decimal :max_budget_cents, precision: 10, scale: 0
      t.string :currency, default: "EUR", null: false
      t.string :status, default: "open", null: false
      t.string :item_category
      t.text :special_instructions

      t.timestamps
    end

    add_index :shipping_requests, :status
    add_index :shipping_requests, [:departure_city, :arrival_city]
    add_index :shipping_requests, :desired_date
  end
end

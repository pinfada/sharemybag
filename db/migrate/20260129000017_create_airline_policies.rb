class CreateAirlinePolicies < ActiveRecord::Migration[7.0]
  def change
    create_table :airline_policies do |t|
      t.string :airline_code, null: false # IATA 2-letter code
      t.string :airline_name, null: false
      t.decimal :max_checked_weight_kg, precision: 5, scale: 2
      t.decimal :max_carry_on_weight_kg, precision: 5, scale: 2
      t.decimal :max_single_item_weight_kg, precision: 5, scale: 2
      t.integer :max_checked_length_cm
      t.integer :max_checked_width_cm
      t.integer :max_checked_height_cm
      t.integer :max_total_dimensions_cm # L+W+H
      t.string :prohibited_items, array: true, default: []
      t.string :restricted_items, array: true, default: []
      t.text :special_requirements
      t.boolean :allows_third_party_items, default: true
      t.string :liability_policy # limited, full, none
      t.string :website_url
      t.boolean :active, default: true
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :airline_policies, :airline_code, unique: true
    add_index :airline_policies, :active
  end
end

class CreateCustomsDeclarations < ActiveRecord::Migration[7.0]
  def change
    create_table :customs_declarations do |t|
      t.references :shipping_request, null: false, foreign_key: true, index: true
      t.references :declared_by, null: false, foreign_key: { to_table: :users }, index: true
      t.string :declaration_number, null: false, index: { unique: true }
      t.string :origin_country, null: false
      t.string :destination_country, null: false
      t.decimal :total_declared_value_cents, precision: 10, null: false
      t.string :currency, default: "EUR", null: false
      t.string :purpose, null: false # personal, commercial, gift, sample, repair
      t.boolean :contains_food, default: false
      t.boolean :contains_plants, default: false
      t.boolean :contains_animal_products, default: false
      t.boolean :contains_medicine, default: false
      t.boolean :contains_electronics, default: false
      t.boolean :contains_currency, default: false
      t.decimal :currency_amount_declared, precision: 10
      t.text :item_descriptions, null: false # JSON array of item descriptions
      t.string :hs_codes, array: true, default: []
      t.boolean :dangerous_goods_declared, default: false
      t.boolean :sender_attestation, default: false, null: false
      t.datetime :attested_at
      t.string :attested_ip
      t.string :status, default: "pending", null: false # pending, validated, flagged, rejected
      t.text :rejection_reason
      t.jsonb :validation_results, default: {}
      t.timestamps
    end

    add_index :customs_declarations, :status
    add_index :customs_declarations, :origin_country
    add_index :customs_declarations, :destination_country
  end
end

class CreateProhibitedItems < ActiveRecord::Migration[7.0]
  def change
    create_table :prohibited_items do |t|
      t.string :name, null: false
      t.string :name_fr
      t.string :category, null: false # iata_class_1 through iata_class_9, customs_restricted, airline_specific
      t.string :iata_class # 1-9 dangerous goods classes
      t.string :un_number # UN identification number
      t.text :description
      t.text :description_fr
      t.boolean :universally_prohibited, default: true
      t.string :restricted_countries, array: true, default: []
      t.string :restricted_airlines, array: true, default: []
      t.boolean :cabin_allowed, default: false
      t.boolean :hold_allowed, default: false
      t.string :max_quantity # e.g., "100ml", "2kg"
      t.boolean :requires_declaration, default: false
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :prohibited_items, :category
    add_index :prohibited_items, :iata_class
    add_index :prohibited_items, :active
  end
end

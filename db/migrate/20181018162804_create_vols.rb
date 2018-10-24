class CreateVols < ActiveRecord::Migration
  def change
    create_table :vols do |t|
      t.string :num_vol
      t.datetime :date_depart
      t.integer :duree
      t.integer :provenance_id
      t.integer :destination_id

      t.timestamps null: false
    end
  end
end

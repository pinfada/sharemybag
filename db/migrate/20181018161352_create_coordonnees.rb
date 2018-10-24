class CreateCoordonnees < ActiveRecord::Migration
  def change
    create_table :coordonnees do |t|
      t.string :titre
      t.string :description
      t.float :latitude
      t.float :longitude
      t.references :airport, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

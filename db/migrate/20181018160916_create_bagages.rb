class CreateBagages < ActiveRecord::Migration[5.0]
  def change
    create_table :bagages do |t|
      t.integer :poids
      t.integer :prix
      t.integer :longueur
      t.integer :largeur
      t.integer :hauteur
      t.references :booking, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

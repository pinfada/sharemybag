class CreatePaquets < ActiveRecord::Migration[5.0]
  def change
    create_table :paquets do |t|
      t.references :user, index: true, foreign_key: true
      t.references :bagage, index: true, foreign_key: true
      t.integer :poids
      t.integer :prix
      t.integer :longueur
      t.integer :largeur
      t.integer :hauteur

      t.timestamps null: false
    end
  end
end

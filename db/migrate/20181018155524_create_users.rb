class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.string :remember_token
      t.references :vol, index: true, foreign_key: true
      t.boolean :admin, default: false

      t.timestamps null: false
    end
  end
end

class CreateMicroposts < ActiveRecord::Migration[5.0]
  def change
    create_table :microposts do |t|
      t.string :content
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :microposts, [:user_id, :created_at]
  end
end

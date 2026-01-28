class CreateConversations < ActiveRecord::Migration[5.0]
  def change
    create_table :conversations do |t|
      t.references :sender, foreign_key: { to_table: :users }, null: false
      t.references :recipient, foreign_key: { to_table: :users }, null: false
      t.references :shipping_request, foreign_key: true

      t.timestamps
    end

    add_index :conversations, [:sender_id, :recipient_id], unique: true
  end
end

class CreateDisputeMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :dispute_messages do |t|
      t.integer :dispute_id, null: false
      t.integer :sender_id, null: false
      t.text :body, null: false
      t.boolean :is_internal, default: false
      t.boolean :read, default: false

      t.timestamps
    end

    add_index :dispute_messages, :dispute_id
    add_index :dispute_messages, :sender_id
    add_foreign_key :dispute_messages, :disputes
    add_foreign_key :dispute_messages, :users, column: :sender_id
  end
end

class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.references :conversation, foreign_key: true, null: false
      t.references :sender, foreign_key: { to_table: :users }, null: false
      t.text :body, null: false
      t.boolean :read, default: false, null: false

      t.timestamps
    end

    add_index :messages, [:conversation_id, :created_at]
  end
end

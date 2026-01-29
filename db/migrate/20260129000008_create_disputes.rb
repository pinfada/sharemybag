class CreateDisputes < ActiveRecord::Migration[7.0]
  def change
    create_table :disputes do |t|
      t.integer :shipping_request_id, null: false
      t.integer :transaction_id, null: false
      t.integer :opened_by_id, null: false
      t.integer :assigned_to_id
      t.string :dispute_type, null: false
      t.string :status, default: "opened", null: false
      t.string :priority, default: "normal"
      t.string :title, null: false
      t.text :description, null: false
      t.string :resolution_type
      t.decimal :resolution_amount_cents, precision: 10
      t.string :resolution_currency
      t.text :resolution_notes
      t.datetime :resolved_at
      t.integer :resolved_by_id
      t.datetime :escalated_at
      t.datetime :auto_escalate_at
      t.datetime :deadline_at
      t.datetime :response_deadline_at
      t.datetime :last_activity_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :disputes, :shipping_request_id
    add_index :disputes, :transaction_id
    add_index :disputes, :opened_by_id
    add_index :disputes, :assigned_to_id
    add_index :disputes, :status
    add_index :disputes, :resolved_by_id
    add_foreign_key :disputes, :shipping_requests
    add_foreign_key :disputes, :transactions
    add_foreign_key :disputes, :users, column: :opened_by_id
    add_foreign_key :disputes, :users, column: :assigned_to_id
    add_foreign_key :disputes, :users, column: :resolved_by_id
  end
end

class CreatePaymentAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :payment_audit_logs do |t|
      t.integer :transaction_id
      t.integer :user_id
      t.string :action, null: false
      t.string :status, null: false
      t.decimal :amount_cents, precision: 10
      t.string :currency
      t.string :stripe_event_id
      t.string :ip_address
      t.text :user_agent
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :payment_audit_logs, :transaction_id
    add_index :payment_audit_logs, :user_id
    add_foreign_key :payment_audit_logs, :transactions
    add_foreign_key :payment_audit_logs, :users
  end
end

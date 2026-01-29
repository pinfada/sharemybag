class EnhanceTransactionsForStripe < ActiveRecord::Migration[7.0]
  def change
    add_column :transactions, :stripe_charge_id, :string
    add_column :transactions, :stripe_refund_id, :string
    add_column :transactions, :idempotency_key, :string
    add_column :transactions, :payment_method, :string
    add_column :transactions, :three_d_secure, :boolean, default: false
    add_column :transactions, :stripe_fee_cents, :decimal, precision: 10, default: 0
    add_column :transactions, :net_platform_fee_cents, :decimal, precision: 10, default: 0
    add_column :transactions, :escrow_released_at, :datetime
    add_column :transactions, :disputed_at, :datetime
    add_column :transactions, :failure_reason, :text
    add_column :transactions, :metadata, :jsonb, default: {}

    add_index :transactions, :stripe_charge_id
    add_index :transactions, :idempotency_key, unique: true
  end
end

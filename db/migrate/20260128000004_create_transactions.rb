class CreateTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :transactions do |t|
      t.references :shipping_request, foreign_key: true, null: false
      t.references :bid, foreign_key: true, null: false
      t.references :sender, foreign_key: { to_table: :users }, null: false
      t.references :traveler, foreign_key: { to_table: :users }, null: false
      t.decimal :amount_cents, precision: 10, scale: 0, null: false
      t.decimal :platform_fee_cents, precision: 10, scale: 0, null: false
      t.decimal :traveler_payout_cents, precision: 10, scale: 0, null: false
      t.string :currency, default: "EUR", null: false
      t.string :status, default: "pending", null: false
      t.string :stripe_payment_intent_id
      t.string :stripe_transfer_id
      t.datetime :paid_at
      t.datetime :released_at
      t.datetime :refunded_at

      t.timestamps
    end

    add_index :transactions, :status
    add_index :transactions, :stripe_payment_intent_id, unique: true
  end
end

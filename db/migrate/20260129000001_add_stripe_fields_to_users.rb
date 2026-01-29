class AddStripeFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_account_id, :string
    add_column :users, :stripe_account_status, :string, default: "pending"
    add_column :users, :stripe_onboarding_completed, :boolean, default: false
    add_column :users, :kyc_required_at, :datetime
    add_column :users, :transactions_count, :integer, default: 0

    add_index :users, :stripe_customer_id, unique: true
    add_index :users, :stripe_account_id, unique: true
  end
end

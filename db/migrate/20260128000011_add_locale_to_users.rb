class AddLocaleToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :locale, :string, default: "fr"
    add_column :users, :currency, :string, default: "EUR"
    add_column :users, :phone, :string
    add_column :users, :bio, :text
    add_column :users, :city, :string
    add_column :users, :country, :string
    add_column :users, :avatar_url, :string
    add_column :users, :email_verified, :boolean, default: false
    add_column :users, :email_verification_token, :string
    add_column :users, :email_verification_sent_at, :datetime
    add_column :users, :password_reset_token, :string
    add_column :users, :password_reset_sent_at, :datetime
  end
end

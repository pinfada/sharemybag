class EnhanceIdentityVerificationsForStripeIdentity < ActiveRecord::Migration[7.0]
  def change
    add_column :identity_verifications, :stripe_verification_session_id, :string
    add_column :identity_verifications, :stripe_verification_report_id, :string
    add_column :identity_verifications, :verification_type, :string, default: "document"
    add_column :identity_verifications, :liveness_check_passed, :boolean
    add_column :identity_verifications, :document_number_hash, :string
    add_column :identity_verifications, :document_country, :string
    add_column :identity_verifications, :document_expiry_date, :date
    add_column :identity_verifications, :first_name_match, :boolean
    add_column :identity_verifications, :last_name_match, :boolean
    add_column :identity_verifications, :dob_match, :boolean
    add_column :identity_verifications, :expires_at, :datetime
    add_column :identity_verifications, :attempts_count, :integer, default: 0
    add_column :identity_verifications, :last_attempt_at, :datetime
    add_column :identity_verifications, :metadata, :jsonb, default: {}

    add_index :identity_verifications, :stripe_verification_session_id
  end
end

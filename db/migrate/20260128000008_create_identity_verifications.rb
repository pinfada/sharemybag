class CreateIdentityVerifications < ActiveRecord::Migration[5.0]
  def change
    create_table :identity_verifications do |t|
      t.references :user, foreign_key: true, null: false
      t.string :document_type, null: false
      t.string :document_front_url
      t.string :document_back_url
      t.string :selfie_url
      t.string :status, default: "pending", null: false
      t.text :rejection_reason
      t.datetime :verified_at
      t.references :verified_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :identity_verifications, :status
  end
end

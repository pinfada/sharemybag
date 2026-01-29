class CreateSecurityScreenings < ActiveRecord::Migration[7.0]
  def change
    create_table :security_screenings do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :shipping_request, foreign_key: true, index: true
      t.string :screening_type, null: false # ofac, sanctions, pep, watchlist, aml
      t.string :status, default: "pending", null: false # pending, cleared, flagged, blocked
      t.string :provider # compliance_api, manual
      t.string :matched_list # OFAC_SDN, UN_SANCTIONS, EU_SANCTIONS, etc.
      t.decimal :match_score, precision: 5, scale: 2
      t.text :match_details
      t.jsonb :api_response, default: {}
      t.boolean :false_positive, default: false
      t.string :reviewed_by_id
      t.datetime :reviewed_at
      t.text :review_notes
      t.datetime :expires_at # screenings are valid for 30 days
      t.timestamps
    end

    add_index :security_screenings, :screening_type
    add_index :security_screenings, :status
    add_index :security_screenings, [:user_id, :screening_type], name: "idx_screenings_user_type"
  end
end

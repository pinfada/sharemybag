class StreamlineSchemaForCoreMarketplace < ActiveRecord::Migration[7.0]
  def up
    # 1. Suppression des clés étrangères et colonnes obsolètes sur les tables conservées
    remove_foreign_key :bids, :kilo_offers if foreign_key_exists?(:bids, :kilo_offers)
    remove_column :bids, :kilo_offer_id, :integer if column_exists?(:bids, :kilo_offer_id)

    remove_foreign_key :users, :vols if foreign_key_exists?(:users, :vols)
    %i[
      vol_id avatar_url email_verified email_verification_token email_verification_sent_at
      password_reset_token password_reset_sent_at stripe_customer_id stripe_account_id
      stripe_account_status stripe_onboarding_completed kyc_required_at transactions_count
    ].each do |col|
      remove_column :users, col if column_exists?(:users, col)
    end

    %i[
      content_declaration_verified declared_value_cents declared_contents
      contains_dangerous_goods insurance_required insurance_value_cents
      compliance_status compliance_checked_at airline_restrictions_checked
    ].each do |col|
      remove_column :shipping_requests, col if column_exists?(:shipping_requests, col)
    end

    %i[
      handover_photo_url delivery_photo_url otp_delivery_code
      otp_required delivery_confirmed_via_otp
    ].each do |col|
      remove_column :shipment_trackings, col if column_exists?(:shipment_trackings, col)
    end

    # 2. Suppression des tables hors périmètre (legacy 2018 + modules non retenus)
    obsolete_tables = %i[
      dispute_evidences dispute_messages disputes
      delivery_confirmations handling_events compliance_checklists
      customs_declarations security_screenings airline_policies prohibited_items
      flight_verifications identity_verifications
      payment_audit_logs stripe_webhook_events transactions
      kilo_offers
      user_bookings paquets bagages bookings coordonnees vols airports
      identities microposts relationships
      blazer_audits blazer_checks blazer_dashboard_queries blazer_dashboards blazer_queries
    ]

    obsolete_tables.each do |table|
      drop_table table, if_exists: true, force: :cascade
    end

    # 3. Renforcement des index et contraintes d'intégrité sur les tables cœur
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email" unless index_exists?(:users, "LOWER(email)", name: "index_users_on_lower_email")
    add_index :users, :remember_token, unique: true unless index_exists?(:users, :remember_token)

    if index_exists?(:shipment_trackings, :shipping_request_id, unique: false)
      remove_index :shipment_trackings, :shipping_request_id
    end
    add_index :shipment_trackings, :shipping_request_id, unique: true unless index_exists?(:shipment_trackings, :shipping_request_id, unique: true)

    change_column_default :shipping_requests, :prohibited_items_acknowledged, from: nil, to: false
    change_column_null :shipping_requests, :prohibited_items_acknowledged, false, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "La simplification du schéma cœur n'est pas réversible."
  end
end

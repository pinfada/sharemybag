# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2026_01_29_000018) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "airline_policies", force: :cascade do |t|
    t.string "airline_code", null: false
    t.string "airline_name", null: false
    t.decimal "max_checked_weight_kg", precision: 5, scale: 2
    t.decimal "max_carry_on_weight_kg", precision: 5, scale: 2
    t.decimal "max_single_item_weight_kg", precision: 5, scale: 2
    t.integer "max_checked_length_cm"
    t.integer "max_checked_width_cm"
    t.integer "max_checked_height_cm"
    t.integer "max_total_dimensions_cm"
    t.string "prohibited_items", default: [], array: true
    t.string "restricted_items", default: [], array: true
    t.text "special_requirements"
    t.boolean "allows_third_party_items", default: true
    t.string "liability_policy"
    t.string "website_url"
    t.boolean "active", default: true
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_airline_policies_on_active"
    t.index ["airline_code"], name: "index_airline_policies_on_airline_code", unique: true
  end

  create_table "airports", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "location"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "bagages", id: :serial, force: :cascade do |t|
    t.integer "poids"
    t.integer "prix"
    t.integer "longueur"
    t.integer "largeur"
    t.integer "hauteur"
    t.integer "booking_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["booking_id"], name: "index_bagages_on_booking_id"
    t.index ["user_id"], name: "index_bagages_on_user_id"
  end

  create_table "bids", id: :serial, force: :cascade do |t|
    t.integer "shipping_request_id", null: false
    t.integer "traveler_id", null: false
    t.integer "kilo_offer_id"
    t.decimal "price_per_kg_cents", precision: 10, null: false
    t.decimal "available_kg", precision: 8, scale: 2, null: false
    t.string "currency", default: "EUR", null: false
    t.date "travel_date", null: false
    t.string "flight_number"
    t.string "status", default: "pending", null: false
    t.text "message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["kilo_offer_id"], name: "index_bids_on_kilo_offer_id"
    t.index ["shipping_request_id", "traveler_id"], name: "index_bids_on_shipping_request_id_and_traveler_id", unique: true
    t.index ["shipping_request_id"], name: "index_bids_on_shipping_request_id"
    t.index ["status"], name: "index_bids_on_status"
    t.index ["traveler_id"], name: "index_bids_on_traveler_id"
  end

  create_table "blazer_audits", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at", precision: nil
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", id: :serial, force: :cascade do |t|
    t.integer "creator_id"
    t.integer "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", id: :serial, force: :cascade do |t|
    t.integer "dashboard_id"
    t.integer "query_id"
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", id: :serial, force: :cascade do |t|
    t.integer "creator_id"
    t.text "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", id: :serial, force: :cascade do |t|
    t.integer "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "bookings", id: :serial, force: :cascade do |t|
    t.string "ref_number"
    t.integer "vol_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_bookings_on_user_id"
    t.index ["vol_id"], name: "index_bookings_on_vol_id"
  end

  create_table "compliance_checklists", force: :cascade do |t|
    t.bigint "shipping_request_id", null: false
    t.bigint "completed_by_id", null: false
    t.boolean "no_prohibited_items", default: false
    t.boolean "no_dangerous_goods", default: false
    t.boolean "accurate_description", default: false
    t.boolean "accurate_weight", default: false
    t.boolean "proper_packaging", default: false
    t.boolean "customs_compliant", default: false
    t.boolean "accepts_liability", default: false
    t.boolean "accepts_inspection", default: false
    t.boolean "identity_verified", default: false
    t.boolean "security_screening_passed", default: false
    t.boolean "sanctions_check_passed", default: false
    t.boolean "customs_declaration_filed", default: false
    t.boolean "airline_policy_checked", default: false
    t.boolean "weight_within_limits", default: false
    t.boolean "dimensions_within_limits", default: false
    t.boolean "fully_compliant", default: false
    t.datetime "completed_at"
    t.string "completed_ip"
    t.string "user_agent"
    t.text "digital_signature"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_by_id"], name: "index_compliance_checklists_on_completed_by_id"
    t.index ["shipping_request_id"], name: "index_compliance_checklists_on_shipping_request_id", unique: true
  end

  create_table "conversations", id: :serial, force: :cascade do |t|
    t.integer "sender_id", null: false
    t.integer "recipient_id", null: false
    t.integer "shipping_request_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["recipient_id"], name: "index_conversations_on_recipient_id"
    t.index ["sender_id", "recipient_id"], name: "index_conversations_on_sender_id_and_recipient_id", unique: true
    t.index ["sender_id"], name: "index_conversations_on_sender_id"
    t.index ["shipping_request_id"], name: "index_conversations_on_shipping_request_id"
  end

  create_table "coordonnees", id: :serial, force: :cascade do |t|
    t.string "titre"
    t.string "description"
    t.float "latitude"
    t.float "longitude"
    t.integer "airport_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["airport_id"], name: "index_coordonnees_on_airport_id"
  end

  create_table "customs_declarations", force: :cascade do |t|
    t.bigint "shipping_request_id", null: false
    t.bigint "declared_by_id", null: false
    t.string "declaration_number", null: false
    t.string "origin_country", null: false
    t.string "destination_country", null: false
    t.decimal "total_declared_value_cents", precision: 10, null: false
    t.string "currency", default: "EUR", null: false
    t.string "purpose", null: false
    t.boolean "contains_food", default: false
    t.boolean "contains_plants", default: false
    t.boolean "contains_animal_products", default: false
    t.boolean "contains_medicine", default: false
    t.boolean "contains_electronics", default: false
    t.boolean "contains_currency", default: false
    t.decimal "currency_amount_declared", precision: 10
    t.text "item_descriptions", null: false
    t.string "hs_codes", default: [], array: true
    t.boolean "dangerous_goods_declared", default: false
    t.boolean "sender_attestation", default: false, null: false
    t.datetime "attested_at"
    t.string "attested_ip"
    t.string "status", default: "pending", null: false
    t.text "rejection_reason"
    t.jsonb "validation_results", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["declaration_number"], name: "index_customs_declarations_on_declaration_number", unique: true
    t.index ["declared_by_id"], name: "index_customs_declarations_on_declared_by_id"
    t.index ["destination_country"], name: "index_customs_declarations_on_destination_country"
    t.index ["origin_country"], name: "index_customs_declarations_on_origin_country"
    t.index ["shipping_request_id"], name: "index_customs_declarations_on_shipping_request_id"
    t.index ["status"], name: "index_customs_declarations_on_status"
  end

  create_table "delivery_confirmations", force: :cascade do |t|
    t.integer "shipment_tracking_id", null: false
    t.integer "sender_id", null: false
    t.integer "traveler_id", null: false
    t.string "otp_digest", null: false
    t.datetime "otp_generated_at", null: false
    t.datetime "otp_expires_at", null: false
    t.datetime "otp_verified_at"
    t.integer "attempts_count", default: 0
    t.integer "max_attempts", default: 3
    t.boolean "blocked", default: false
    t.datetime "blocked_at"
    t.string "delivery_photo_url"
    t.decimal "delivery_latitude", precision: 10, scale: 7
    t.decimal "delivery_longitude", precision: 10, scale: 7
    t.string "delivery_address"
    t.boolean "sms_sent", default: false
    t.datetime "sms_sent_at"
    t.string "sms_provider"
    t.string "sms_message_sid"
    t.boolean "email_sent", default: false
    t.datetime "email_sent_at"
    t.string "notification_channel"
    t.string "confirmed_by_ip"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sender_id"], name: "index_delivery_confirmations_on_sender_id"
    t.index ["shipment_tracking_id"], name: "index_delivery_confirmations_on_shipment_tracking_id", unique: true
    t.index ["traveler_id"], name: "index_delivery_confirmations_on_traveler_id"
  end

  create_table "dispute_evidences", force: :cascade do |t|
    t.integer "dispute_id", null: false
    t.integer "submitted_by_id", null: false
    t.string "evidence_type", null: false
    t.string "file_url"
    t.text "description"
    t.string "content_hash"
    t.integer "file_size_bytes"
    t.string "mime_type"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_id"], name: "index_dispute_evidences_on_dispute_id"
    t.index ["submitted_by_id"], name: "index_dispute_evidences_on_submitted_by_id"
  end

  create_table "dispute_messages", force: :cascade do |t|
    t.integer "dispute_id", null: false
    t.integer "sender_id", null: false
    t.text "body", null: false
    t.boolean "is_internal", default: false
    t.boolean "read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_id"], name: "index_dispute_messages_on_dispute_id"
    t.index ["sender_id"], name: "index_dispute_messages_on_sender_id"
  end

  create_table "disputes", force: :cascade do |t|
    t.integer "shipping_request_id", null: false
    t.integer "transaction_id", null: false
    t.integer "opened_by_id", null: false
    t.integer "assigned_to_id"
    t.string "dispute_type", null: false
    t.string "status", default: "opened", null: false
    t.string "priority", default: "normal"
    t.string "title", null: false
    t.text "description", null: false
    t.string "resolution_type"
    t.decimal "resolution_amount_cents", precision: 10
    t.string "resolution_currency"
    t.text "resolution_notes"
    t.datetime "resolved_at"
    t.integer "resolved_by_id"
    t.datetime "escalated_at"
    t.datetime "auto_escalate_at"
    t.datetime "deadline_at"
    t.datetime "response_deadline_at"
    t.datetime "last_activity_at"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_disputes_on_assigned_to_id"
    t.index ["opened_by_id"], name: "index_disputes_on_opened_by_id"
    t.index ["resolved_by_id"], name: "index_disputes_on_resolved_by_id"
    t.index ["shipping_request_id"], name: "index_disputes_on_shipping_request_id"
    t.index ["status"], name: "index_disputes_on_status"
    t.index ["transaction_id"], name: "index_disputes_on_transaction_id"
  end

  create_table "flight_verifications", force: :cascade do |t|
    t.integer "kilo_offer_id", null: false
    t.integer "user_id", null: false
    t.string "flight_number", null: false
    t.string "airline_code"
    t.string "departure_airport", null: false
    t.string "arrival_airport", null: false
    t.date "departure_date", null: false
    t.time "departure_time"
    t.time "arrival_time"
    t.string "status", default: "pending", null: false
    t.string "verification_source"
    t.string "ticket_url"
    t.jsonb "ticket_data", default: {}
    t.string "passenger_name"
    t.decimal "name_match_score", precision: 5, scale: 2
    t.jsonb "api_response", default: {}
    t.text "rejection_reason"
    t.datetime "verified_at"
    t.jsonb "fraud_flags", default: []
    t.integer "attempts_today", default: 0
    t.datetime "last_attempt_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kilo_offer_id"], name: "index_flight_verifications_on_kilo_offer_id", unique: true
    t.index ["status"], name: "index_flight_verifications_on_status"
    t.index ["user_id"], name: "index_flight_verifications_on_user_id"
  end

  create_table "handling_events", force: :cascade do |t|
    t.bigint "shipment_tracking_id", null: false
    t.bigint "actor_id"
    t.string "event_type", null: false
    t.string "location"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "photo_url"
    t.text "notes"
    t.string "signature_url"
    t.string "barcode_scanned"
    t.string "seal_number"
    t.boolean "seal_intact"
    t.string "content_hash", null: false
    t.string "previous_event_hash"
    t.jsonb "environmental_data", default: {}
    t.string "device_id"
    t.boolean "anomaly_detected", default: false
    t.text "anomaly_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_handling_events_on_actor_id"
    t.index ["content_hash"], name: "index_handling_events_on_content_hash", unique: true
    t.index ["event_type"], name: "index_handling_events_on_event_type"
    t.index ["shipment_tracking_id", "created_at"], name: "idx_handling_events_tracking_timeline"
    t.index ["shipment_tracking_id"], name: "index_handling_events_on_shipment_tracking_id"
  end

  create_table "identities", id: :serial, force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "identity_verifications", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "document_type", null: false
    t.string "document_front_url"
    t.string "document_back_url"
    t.string "selfie_url"
    t.string "status", default: "pending", null: false
    t.text "rejection_reason"
    t.datetime "verified_at", precision: nil
    t.integer "verified_by_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "stripe_verification_session_id"
    t.string "stripe_verification_report_id"
    t.string "verification_type", default: "document"
    t.boolean "liveness_check_passed"
    t.string "document_number_hash"
    t.string "document_country"
    t.date "document_expiry_date"
    t.boolean "first_name_match"
    t.boolean "last_name_match"
    t.boolean "dob_match"
    t.datetime "expires_at"
    t.integer "attempts_count", default: 0
    t.datetime "last_attempt_at"
    t.jsonb "metadata", default: {}
    t.index ["status"], name: "index_identity_verifications_on_status"
    t.index ["stripe_verification_session_id"], name: "index_identity_verifications_on_stripe_verification_session_id"
    t.index ["user_id"], name: "index_identity_verifications_on_user_id"
    t.index ["verified_by_id"], name: "index_identity_verifications_on_verified_by_id"
  end

  create_table "kilo_offers", id: :serial, force: :cascade do |t|
    t.integer "traveler_id", null: false
    t.integer "vol_id"
    t.string "departure_city", null: false
    t.string "departure_country", null: false
    t.string "arrival_city", null: false
    t.string "arrival_country", null: false
    t.date "travel_date", null: false
    t.decimal "available_kg", precision: 8, scale: 2, null: false
    t.decimal "price_per_kg_cents", precision: 10, null: false
    t.string "currency", default: "EUR", null: false
    t.string "status", default: "active", null: false
    t.text "accepted_items"
    t.text "restrictions"
    t.string "flight_number"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["departure_city", "arrival_city"], name: "index_kilo_offers_on_departure_city_and_arrival_city"
    t.index ["status"], name: "index_kilo_offers_on_status"
    t.index ["travel_date"], name: "index_kilo_offers_on_travel_date"
    t.index ["traveler_id"], name: "index_kilo_offers_on_traveler_id"
    t.index ["vol_id"], name: "index_kilo_offers_on_vol_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "conversation_id", null: false
    t.integer "sender_id", null: false
    t.text "body", null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "microposts", id: :serial, force: :cascade do |t|
    t.string "content"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id", "created_at"], name: "index_microposts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_microposts_on_user_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "notifiable_type", null: false
    t.integer "notifiable_id", null: false
    t.string "action", null: false
    t.text "message"
    t.boolean "read", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "paquets", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "bagage_id"
    t.integer "poids"
    t.integer "prix"
    t.integer "longueur"
    t.integer "largeur"
    t.integer "hauteur"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["bagage_id"], name: "index_paquets_on_bagage_id"
    t.index ["user_id"], name: "index_paquets_on_user_id"
  end

  create_table "payment_audit_logs", force: :cascade do |t|
    t.integer "transaction_id"
    t.integer "user_id"
    t.string "action", null: false
    t.string "status", null: false
    t.decimal "amount_cents", precision: 10
    t.string "currency"
    t.string "stripe_event_id"
    t.string "ip_address"
    t.text "user_agent"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transaction_id"], name: "index_payment_audit_logs_on_transaction_id"
    t.index ["user_id"], name: "index_payment_audit_logs_on_user_id"
  end

  create_table "prohibited_items", force: :cascade do |t|
    t.string "name", null: false
    t.string "name_fr"
    t.string "category", null: false
    t.string "iata_class"
    t.string "un_number"
    t.text "description"
    t.text "description_fr"
    t.boolean "universally_prohibited", default: true
    t.string "restricted_countries", default: [], array: true
    t.string "restricted_airlines", default: [], array: true
    t.boolean "cabin_allowed", default: false
    t.boolean "hold_allowed", default: false
    t.string "max_quantity"
    t.boolean "requires_declaration", default: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_prohibited_items_on_active"
    t.index ["category"], name: "index_prohibited_items_on_category"
    t.index ["iata_class"], name: "index_prohibited_items_on_iata_class"
  end

  create_table "relationships", id: :serial, force: :cascade do |t|
    t.integer "followed_id"
    t.integer "follower_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["followed_id"], name: "index_relationships_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_relationships_on_follower_id"
  end

  create_table "reviews", id: :serial, force: :cascade do |t|
    t.integer "reviewer_id", null: false
    t.integer "reviewee_id", null: false
    t.integer "shipping_request_id", null: false
    t.integer "rating", null: false
    t.text "comment"
    t.string "role", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewer_id", "shipping_request_id"], name: "index_reviews_on_reviewer_id_and_shipping_request_id", unique: true
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
    t.index ["shipping_request_id"], name: "index_reviews_on_shipping_request_id"
  end

  create_table "security_screenings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "shipping_request_id"
    t.string "screening_type", null: false
    t.string "status", default: "pending", null: false
    t.string "provider"
    t.string "matched_list"
    t.decimal "match_score", precision: 5, scale: 2
    t.text "match_details"
    t.jsonb "api_response", default: {}
    t.boolean "false_positive", default: false
    t.string "reviewed_by_id"
    t.datetime "reviewed_at"
    t.text "review_notes"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["screening_type"], name: "index_security_screenings_on_screening_type"
    t.index ["shipping_request_id"], name: "index_security_screenings_on_shipping_request_id"
    t.index ["status"], name: "index_security_screenings_on_status"
    t.index ["user_id", "screening_type"], name: "idx_screenings_user_type"
    t.index ["user_id"], name: "index_security_screenings_on_user_id"
  end

  create_table "shipment_trackings", id: :serial, force: :cascade do |t|
    t.integer "shipping_request_id", null: false
    t.integer "traveler_id", null: false
    t.string "status", default: "created", null: false
    t.string "handover_code"
    t.string "delivery_code"
    t.string "handover_photo_url"
    t.string "delivery_photo_url"
    t.datetime "handed_over_at", precision: nil
    t.datetime "in_transit_at", precision: nil
    t.datetime "delivered_at", precision: nil
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "otp_delivery_code"
    t.boolean "otp_required", default: false
    t.boolean "delivery_confirmed_via_otp", default: false
    t.index ["delivery_code"], name: "index_shipment_trackings_on_delivery_code", unique: true
    t.index ["handover_code"], name: "index_shipment_trackings_on_handover_code", unique: true
    t.index ["shipping_request_id"], name: "index_shipment_trackings_on_shipping_request_id"
    t.index ["status"], name: "index_shipment_trackings_on_status"
    t.index ["traveler_id"], name: "index_shipment_trackings_on_traveler_id"
  end

  create_table "shipping_requests", id: :serial, force: :cascade do |t|
    t.integer "sender_id", null: false
    t.string "title", null: false
    t.text "description"
    t.decimal "weight_kg", precision: 8, scale: 2, null: false
    t.decimal "length_cm", precision: 8, scale: 2
    t.decimal "width_cm", precision: 8, scale: 2
    t.decimal "height_cm", precision: 8, scale: 2
    t.string "departure_city", null: false
    t.string "departure_country", null: false
    t.string "arrival_city", null: false
    t.string "arrival_country", null: false
    t.date "desired_date", null: false
    t.date "deadline_date"
    t.decimal "max_budget_cents", precision: 10
    t.string "currency", default: "EUR", null: false
    t.string "status", default: "open", null: false
    t.string "item_category"
    t.text "special_instructions"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "prohibited_items_acknowledged", default: false
    t.boolean "content_declaration_verified", default: false
    t.decimal "declared_value_cents", precision: 10
    t.jsonb "declared_contents", default: []
    t.boolean "contains_dangerous_goods", default: false
    t.boolean "insurance_required", default: false
    t.decimal "insurance_value_cents", precision: 10
    t.string "compliance_status", default: "pending"
    t.datetime "compliance_checked_at"
    t.boolean "airline_restrictions_checked", default: false
    t.index ["compliance_status"], name: "index_shipping_requests_on_compliance_status"
    t.index ["departure_city", "arrival_city"], name: "index_shipping_requests_on_departure_city_and_arrival_city"
    t.index ["desired_date"], name: "index_shipping_requests_on_desired_date"
    t.index ["sender_id"], name: "index_shipping_requests_on_sender_id"
    t.index ["status"], name: "index_shipping_requests_on_status"
  end

  create_table "stripe_webhook_events", force: :cascade do |t|
    t.string "stripe_event_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.boolean "processed", default: false
    t.text "processing_errors"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_stripe_webhook_events_on_event_type"
    t.index ["stripe_event_id"], name: "index_stripe_webhook_events_on_stripe_event_id", unique: true
  end

  create_table "transactions", id: :serial, force: :cascade do |t|
    t.integer "shipping_request_id", null: false
    t.integer "bid_id", null: false
    t.integer "sender_id", null: false
    t.integer "traveler_id", null: false
    t.decimal "amount_cents", precision: 10, null: false
    t.decimal "platform_fee_cents", precision: 10, null: false
    t.decimal "traveler_payout_cents", precision: 10, null: false
    t.string "currency", default: "EUR", null: false
    t.string "status", default: "pending", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_transfer_id"
    t.datetime "paid_at", precision: nil
    t.datetime "released_at", precision: nil
    t.datetime "refunded_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "stripe_charge_id"
    t.string "stripe_refund_id"
    t.string "idempotency_key"
    t.string "payment_method"
    t.boolean "three_d_secure", default: false
    t.decimal "stripe_fee_cents", precision: 10, default: "0"
    t.decimal "net_platform_fee_cents", precision: 10, default: "0"
    t.datetime "escrow_released_at"
    t.datetime "disputed_at"
    t.text "failure_reason"
    t.jsonb "metadata", default: {}
    t.index ["bid_id"], name: "index_transactions_on_bid_id"
    t.index ["idempotency_key"], name: "index_transactions_on_idempotency_key", unique: true
    t.index ["sender_id"], name: "index_transactions_on_sender_id"
    t.index ["shipping_request_id"], name: "index_transactions_on_shipping_request_id"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["stripe_charge_id"], name: "index_transactions_on_stripe_charge_id"
    t.index ["stripe_payment_intent_id"], name: "index_transactions_on_stripe_payment_intent_id", unique: true
    t.index ["traveler_id"], name: "index_transactions_on_traveler_id"
  end

  create_table "user_bookings", id: :serial, force: :cascade do |t|
    t.integer "booking_id"
    t.integer "user_id"
    t.integer "bagage_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["bagage_id"], name: "index_user_bookings_on_bagage_id"
    t.index ["booking_id"], name: "index_user_bookings_on_booking_id"
    t.index ["user_id"], name: "index_user_bookings_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.string "remember_token"
    t.integer "vol_id"
    t.boolean "admin", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "locale", default: "fr"
    t.string "currency", default: "EUR"
    t.string "phone"
    t.text "bio"
    t.string "city"
    t.string "country"
    t.string "avatar_url"
    t.boolean "email_verified", default: false
    t.string "email_verification_token"
    t.datetime "email_verification_sent_at", precision: nil
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at", precision: nil
    t.string "stripe_customer_id"
    t.string "stripe_account_id"
    t.string "stripe_account_status", default: "pending"
    t.boolean "stripe_onboarding_completed", default: false
    t.datetime "kyc_required_at"
    t.integer "transactions_count", default: 0
    t.index ["stripe_account_id"], name: "index_users_on_stripe_account_id", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
    t.index ["vol_id"], name: "index_users_on_vol_id"
  end

  create_table "vols", id: :serial, force: :cascade do |t|
    t.string "num_vol"
    t.datetime "date_depart", precision: nil
    t.integer "duree"
    t.integer "provenance_id"
    t.integer "destination_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  add_foreign_key "bagages", "bookings"
  add_foreign_key "bagages", "users"
  add_foreign_key "bids", "kilo_offers"
  add_foreign_key "bids", "shipping_requests"
  add_foreign_key "bids", "users", column: "traveler_id"
  add_foreign_key "bookings", "users"
  add_foreign_key "bookings", "vols"
  add_foreign_key "compliance_checklists", "shipping_requests"
  add_foreign_key "compliance_checklists", "users", column: "completed_by_id"
  add_foreign_key "conversations", "shipping_requests"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "coordonnees", "airports"
  add_foreign_key "customs_declarations", "shipping_requests"
  add_foreign_key "customs_declarations", "users", column: "declared_by_id"
  add_foreign_key "delivery_confirmations", "shipment_trackings"
  add_foreign_key "delivery_confirmations", "users", column: "sender_id"
  add_foreign_key "delivery_confirmations", "users", column: "traveler_id"
  add_foreign_key "dispute_evidences", "disputes"
  add_foreign_key "dispute_evidences", "users", column: "submitted_by_id"
  add_foreign_key "dispute_messages", "disputes"
  add_foreign_key "dispute_messages", "users", column: "sender_id"
  add_foreign_key "disputes", "shipping_requests"
  add_foreign_key "disputes", "transactions"
  add_foreign_key "disputes", "users", column: "assigned_to_id"
  add_foreign_key "disputes", "users", column: "opened_by_id"
  add_foreign_key "disputes", "users", column: "resolved_by_id"
  add_foreign_key "flight_verifications", "kilo_offers"
  add_foreign_key "flight_verifications", "users"
  add_foreign_key "handling_events", "shipment_trackings"
  add_foreign_key "handling_events", "users", column: "actor_id"
  add_foreign_key "identities", "users"
  add_foreign_key "identity_verifications", "users"
  add_foreign_key "identity_verifications", "users", column: "verified_by_id"
  add_foreign_key "kilo_offers", "users", column: "traveler_id"
  add_foreign_key "kilo_offers", "vols"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "microposts", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "paquets", "bagages"
  add_foreign_key "paquets", "users"
  add_foreign_key "payment_audit_logs", "transactions"
  add_foreign_key "payment_audit_logs", "users"
  add_foreign_key "reviews", "shipping_requests"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "security_screenings", "shipping_requests"
  add_foreign_key "security_screenings", "users"
  add_foreign_key "shipment_trackings", "shipping_requests"
  add_foreign_key "shipment_trackings", "users", column: "traveler_id"
  add_foreign_key "shipping_requests", "users", column: "sender_id"
  add_foreign_key "transactions", "bids"
  add_foreign_key "transactions", "shipping_requests"
  add_foreign_key "transactions", "users", column: "sender_id"
  add_foreign_key "transactions", "users", column: "traveler_id"
  add_foreign_key "user_bookings", "bagages"
  add_foreign_key "user_bookings", "bookings"
  add_foreign_key "user_bookings", "users"
  add_foreign_key "users", "vols"
end

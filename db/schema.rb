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

ActiveRecord::Schema[7.0].define(version: 2026_01_28_000011) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.index ["status"], name: "index_identity_verifications_on_status"
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
    t.index ["departure_city", "arrival_city"], name: "index_shipping_requests_on_departure_city_and_arrival_city"
    t.index ["desired_date"], name: "index_shipping_requests_on_desired_date"
    t.index ["sender_id"], name: "index_shipping_requests_on_sender_id"
    t.index ["status"], name: "index_shipping_requests_on_status"
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
    t.index ["bid_id"], name: "index_transactions_on_bid_id"
    t.index ["sender_id"], name: "index_transactions_on_sender_id"
    t.index ["shipping_request_id"], name: "index_transactions_on_shipping_request_id"
    t.index ["status"], name: "index_transactions_on_status"
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
  add_foreign_key "conversations", "shipping_requests"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "coordonnees", "airports"
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
  add_foreign_key "reviews", "shipping_requests"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
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

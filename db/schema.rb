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

ActiveRecord::Schema[7.0].define(version: 2026_11_24_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bids", id: :serial, force: :cascade do |t|
    t.integer "shipping_request_id", null: false
    t.integer "traveler_id", null: false
    t.decimal "price_per_kg_cents", precision: 10, null: false
    t.decimal "available_kg", precision: 8, scale: 2, null: false
    t.string "currency", default: "EUR", null: false
    t.date "travel_date", null: false
    t.string "flight_number"
    t.string "status", default: "pending", null: false
    t.text "message"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["shipping_request_id", "traveler_id"], name: "index_bids_on_shipping_request_id_and_traveler_id", unique: true
    t.index ["shipping_request_id"], name: "index_bids_on_shipping_request_id"
    t.index ["status"], name: "index_bids_on_status"
    t.index ["traveler_id"], name: "index_bids_on_traveler_id"
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
    t.datetime "handed_over_at", precision: nil
    t.datetime "in_transit_at", precision: nil
    t.datetime "delivered_at", precision: nil
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "open_inspection_confirmed_at"
    t.index ["delivery_code"], name: "index_shipment_trackings_on_delivery_code", unique: true
    t.index ["handover_code"], name: "index_shipment_trackings_on_handover_code", unique: true
    t.index ["shipping_request_id"], name: "index_shipment_trackings_on_shipping_request_id", unique: true
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
    t.boolean "prohibited_items_acknowledged", default: false, null: false
    t.integer "declared_value_cents"
    t.index ["departure_city", "arrival_city"], name: "index_shipping_requests_on_departure_city_and_arrival_city"
    t.index ["desired_date"], name: "index_shipping_requests_on_desired_date"
    t.index ["sender_id"], name: "index_shipping_requests_on_sender_id"
    t.index ["status"], name: "index_shipping_requests_on_status"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.string "remember_token"
    t.boolean "admin", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "locale", default: "fr"
    t.string "currency", default: "EUR"
    t.string "phone"
    t.text "bio"
    t.string "city"
    t.string "country"
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
  end

  add_foreign_key "bids", "shipping_requests"
  add_foreign_key "bids", "users", column: "traveler_id"
  add_foreign_key "conversations", "shipping_requests"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "reviews", "shipping_requests"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "shipment_trackings", "shipping_requests"
  add_foreign_key "shipment_trackings", "users", column: "traveler_id"
  add_foreign_key "shipping_requests", "users", column: "sender_id"
end

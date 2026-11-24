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

ActiveRecord::Schema[7.0].define(version: 2026_11_24_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aircraft_types", force: :cascade do |t|
    t.string "code", null: false
    t.string "aircraft_name", null: false
    t.string "manufacturer", null: false
    t.integer "seat_capacity", null: false
    t.decimal "default_baggage_kg_per_pax", precision: 5, scale: 2, default: "23.0", null: false
    t.decimal "max_baggage_payload_kg", precision: 8, scale: 2, null: false
    t.decimal "fuel_burn_rate_per_kg_hour", precision: 6, scale: 4, default: "0.035", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_aircraft_types_on_code", unique: true
  end

  create_table "airline_connectors", force: :cascade do |t|
    t.string "airline_code", null: false
    t.string "airline_name", null: false
    t.string "provider", default: "sandbox", null: false
    t.string "accounting_prefix", default: "057", null: false
    t.string "api_base_url"
    t.string "auth_mode", default: "oauth2_mtls", null: false
    t.string "credentials_ref"
    t.string "webhook_signing_secret_ref"
    t.integer "timeout_seconds", default: 5, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airline_code"], name: "index_airline_connectors_on_airline_code", unique: true
  end

  create_table "dcs_sync_events", force: :cascade do |t|
    t.bigint "kilo_trade_id", null: false
    t.bigint "airline_connector_id", null: false
    t.string "idempotency_key", null: false
    t.string "operation", null: false
    t.string "pnr_code", null: false
    t.string "status", default: "pending", null: false
    t.string "external_reference"
    t.string "iata_rfic"
    t.string "iata_rfisc"
    t.string "ssr_code"
    t.jsonb "request_payload", default: {}, null: false
    t.jsonb "response_payload", default: {}, null: false
    t.string "error_message"
    t.integer "latency_ms"
    t.integer "attempts", default: 0, null: false
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airline_connector_id"], name: "index_dcs_sync_events_on_airline_connector_id"
    t.index ["idempotency_key"], name: "index_dcs_sync_events_on_idempotency_key", unique: true
    t.index ["kilo_trade_id", "operation"], name: "index_dcs_sync_events_on_kilo_trade_id_and_operation"
    t.index ["kilo_trade_id"], name: "index_dcs_sync_events_on_kilo_trade_id"
    t.index ["status"], name: "index_dcs_sync_events_on_status"
  end

  create_table "flights", force: :cascade do |t|
    t.string "flight_number", null: false
    t.string "airline_name", null: false
    t.string "airline_code", null: false
    t.bigint "aircraft_type_id", null: false
    t.string "departure_iata", null: false
    t.string "departure_city", null: false
    t.string "arrival_iata", null: false
    t.string "arrival_city", null: false
    t.datetime "departure_at", null: false
    t.decimal "flight_duration_hours", precision: 5, scale: 2, null: false
    t.integer "airport_excess_fee_per_kg_cents", default: 1500, null: false
    t.integer "airline_commission_bps", default: 2500, null: false
    t.decimal "base_booked_baggage_kg", precision: 8, scale: 2, default: "0.0", null: false
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aircraft_type_id"], name: "index_flights_on_aircraft_type_id"
    t.index ["airline_code"], name: "index_flights_on_airline_code"
    t.index ["departure_at"], name: "index_flights_on_departure_at"
    t.index ["flight_number", "departure_at"], name: "index_flights_on_flight_number_and_departure_at"
    t.index ["status"], name: "index_flights_on_status"
  end

  create_table "kilo_orders", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.bigint "passenger_booking_id", null: false
    t.bigint "user_id", null: false
    t.string "side", null: false
    t.decimal "quantity_kg", precision: 5, scale: 2, null: false
    t.decimal "remaining_kg", precision: 5, scale: 2, null: false
    t.integer "price_per_kg_cents", null: false
    t.string "payout_preference", default: "voucher", null: false
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id", "side", "status", "price_per_kg_cents", "created_at"], name: "idx_kilo_orders_order_book"
    t.index ["flight_id"], name: "index_kilo_orders_on_flight_id"
    t.index ["passenger_booking_id"], name: "index_kilo_orders_on_passenger_booking_id"
    t.index ["user_id", "flight_id", "status"], name: "idx_kilo_orders_user_flight_status"
    t.index ["user_id"], name: "index_kilo_orders_on_user_id"
  end

  create_table "kilo_trades", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.bigint "buy_order_id", null: false
    t.bigint "sell_order_id", null: false
    t.bigint "buyer_id", null: false
    t.bigint "seller_id", null: false
    t.decimal "quantity_kg", precision: 5, scale: 2, null: false
    t.integer "execution_price_per_kg_cents", null: false
    t.integer "gross_amount_cents", null: false
    t.integer "airline_fee_cents", null: false
    t.integer "seller_payout_cents", null: false
    t.string "payout_type", default: "voucher", null: false
    t.integer "estimated_fuel_cost_cents", default: 0, null: false
    t.integer "airline_net_margin_cents", default: 0, null: false
    t.integer "buyer_savings_cents", default: 0, null: false
    t.datetime "executed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dcs_sync_status", default: "pending", null: false
    t.string "buyer_emd_reference"
    t.string "seller_voucher_emd_reference"
    t.datetime "dcs_synced_at"
    t.index ["buy_order_id"], name: "index_kilo_trades_on_buy_order_id"
    t.index ["buyer_id"], name: "index_kilo_trades_on_buyer_id"
    t.index ["flight_id", "executed_at"], name: "index_kilo_trades_on_flight_id_and_executed_at"
    t.index ["flight_id"], name: "index_kilo_trades_on_flight_id"
    t.index ["sell_order_id"], name: "index_kilo_trades_on_sell_order_id"
    t.index ["seller_id"], name: "index_kilo_trades_on_seller_id"
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

  create_table "passenger_bookings", force: :cascade do |t|
    t.string "pnr_code", null: false
    t.bigint "user_id", null: false
    t.bigint "flight_id", null: false
    t.string "cabin_class", default: "economy", null: false
    t.decimal "base_allowance_kg", precision: 5, scale: 2, default: "23.0", null: false
    t.decimal "current_allowance_kg", precision: 5, scale: 2, default: "23.0", null: false
    t.decimal "max_allowance_kg", precision: 5, scale: 2, default: "46.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dcs_sync_status", default: "synced", null: false
    t.string "last_dcs_reference"
    t.datetime "last_dcs_synced_at"
    t.index ["flight_id"], name: "index_passenger_bookings_on_flight_id"
    t.index ["pnr_code"], name: "index_passenger_bookings_on_pnr_code", unique: true
    t.index ["user_id", "flight_id"], name: "index_passenger_bookings_on_user_id_and_flight_id", unique: true
    t.index ["user_id"], name: "index_passenger_bookings_on_user_id"
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
    t.string "role", default: "passenger", null: false
    t.integer "voucher_balance_cents", default: 0, null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
  end

  add_foreign_key "dcs_sync_events", "airline_connectors"
  add_foreign_key "dcs_sync_events", "kilo_trades"
  add_foreign_key "flights", "aircraft_types"
  add_foreign_key "kilo_orders", "flights"
  add_foreign_key "kilo_orders", "passenger_bookings"
  add_foreign_key "kilo_orders", "users"
  add_foreign_key "kilo_trades", "flights"
  add_foreign_key "kilo_trades", "kilo_orders", column: "buy_order_id"
  add_foreign_key "kilo_trades", "kilo_orders", column: "sell_order_id"
  add_foreign_key "kilo_trades", "users", column: "buyer_id"
  add_foreign_key "kilo_trades", "users", column: "seller_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "passenger_bookings", "flights"
  add_foreign_key "passenger_bookings", "users"
end

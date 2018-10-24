# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181018162804) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "airports", force: :cascade do |t|
    t.string   "code"
    t.string   "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bagages", force: :cascade do |t|
    t.integer  "poids"
    t.integer  "prix"
    t.integer  "longueur"
    t.integer  "largeur"
    t.integer  "hauteur"
    t.integer  "booking_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_bagages_on_booking_id", using: :btree
    t.index ["user_id"], name: "index_bagages_on_user_id", using: :btree
  end

  create_table "bookings", force: :cascade do |t|
    t.string   "ref_number"
    t.integer  "vol_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bookings_on_user_id", using: :btree
    t.index ["vol_id"], name: "index_bookings_on_vol_id", using: :btree
  end

  create_table "coordonnees", force: :cascade do |t|
    t.string   "titre"
    t.string   "description"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "airport_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["airport_id"], name: "index_coordonnees_on_airport_id", using: :btree
  end

  create_table "identities", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_identities_on_user_id", using: :btree
  end

  create_table "microposts", force: :cascade do |t|
    t.string   "content"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_microposts_on_user_id_and_created_at", using: :btree
    t.index ["user_id"], name: "index_microposts_on_user_id", using: :btree
  end

  create_table "paquets", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "bagage_id"
    t.integer  "poids"
    t.integer  "prix"
    t.integer  "longueur"
    t.integer  "largeur"
    t.integer  "hauteur"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bagage_id"], name: "index_paquets_on_bagage_id", using: :btree
    t.index ["user_id"], name: "index_paquets_on_user_id", using: :btree
  end

  create_table "relationships", force: :cascade do |t|
    t.integer  "followed_id"
    t.integer  "follower_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["followed_id"], name: "index_relationships_on_followed_id", using: :btree
    t.index ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true, using: :btree
    t.index ["follower_id"], name: "index_relationships_on_follower_id", using: :btree
  end

  create_table "user_bookings", force: :cascade do |t|
    t.integer  "booking_id"
    t.integer  "user_id"
    t.integer  "bagage_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bagage_id"], name: "index_user_bookings_on_bagage_id", using: :btree
    t.index ["booking_id"], name: "index_user_bookings_on_booking_id", using: :btree
    t.index ["user_id"], name: "index_user_bookings_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "remember_token"
    t.integer  "vol_id"
    t.boolean  "admin",           default: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["vol_id"], name: "index_users_on_vol_id", using: :btree
  end

  create_table "vols", force: :cascade do |t|
    t.string   "num_vol"
    t.datetime "date_depart"
    t.integer  "duree"
    t.integer  "provenance_id"
    t.integer  "destination_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

end

class CreateFlightVerifications < ActiveRecord::Migration[7.0]
  def change
    create_table :flight_verifications do |t|
      t.integer :kilo_offer_id, null: false
      t.integer :user_id, null: false
      t.string :flight_number, null: false
      t.string :airline_code
      t.string :departure_airport, null: false
      t.string :arrival_airport, null: false
      t.date :departure_date, null: false
      t.time :departure_time
      t.time :arrival_time
      t.string :status, default: "pending", null: false
      t.string :verification_source
      t.string :ticket_url
      t.jsonb :ticket_data, default: {}
      t.string :passenger_name
      t.decimal :name_match_score, precision: 5, scale: 2
      t.jsonb :api_response, default: {}
      t.text :rejection_reason
      t.datetime :verified_at
      t.jsonb :fraud_flags, default: []
      t.integer :attempts_today, default: 0
      t.datetime :last_attempt_at

      t.timestamps
    end

    add_index :flight_verifications, :kilo_offer_id, unique: true
    add_index :flight_verifications, :user_id
    add_index :flight_verifications, :status
    add_foreign_key :flight_verifications, :kilo_offers
    add_foreign_key :flight_verifications, :users
  end
end

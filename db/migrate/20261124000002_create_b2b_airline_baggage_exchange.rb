class CreateB2bAirlineBaggageExchange < ActiveRecord::Migration[7.0]
  def up
    %i[reviews messages conversations shipment_trackings bids shipping_requests].each do |table_name|
      drop_table table_name, if_exists: true, force: :cascade
    end

    add_column :users, :role, :string, null: false, default: "passenger" unless column_exists?(:users, :role)
    add_column :users, :voucher_balance_cents, :integer, null: false, default: 0 unless column_exists?(:users, :voucher_balance_cents)

    create_table :aircraft_types do |t|
      t.string  :code, null: false
      t.string  :aircraft_name, null: false
      t.string  :manufacturer, null: false
      t.integer :seat_capacity, null: false
      t.decimal :default_baggage_kg_per_pax, precision: 5, scale: 2, null: false, default: 23.0
      t.decimal :max_baggage_payload_kg, precision: 8, scale: 2, null: false
      t.decimal :fuel_burn_rate_per_kg_hour, precision: 6, scale: 4, null: false, default: 0.035

      t.timestamps
    end
    add_index :aircraft_types, :code, unique: true

    create_table :flights do |t|
      t.string     :flight_number, null: false
      t.string     :airline_name, null: false
      t.string     :airline_code, null: false
      t.references :aircraft_type, null: false, foreign_key: true
      t.string     :departure_iata, null: false
      t.string     :departure_city, null: false
      t.string     :arrival_iata, null: false
      t.string     :arrival_city, null: false
      t.datetime   :departure_at, null: false
      t.decimal    :flight_duration_hours, precision: 5, scale: 2, null: false
      t.integer    :airport_excess_fee_per_kg_cents, null: false, default: 1500
      t.integer    :airline_commission_bps, null: false, default: 2500
      t.decimal    :base_booked_baggage_kg, precision: 8, scale: 2, null: false, default: 0.0
      t.string     :status, null: false, default: "open"

      t.timestamps
    end
    add_index :flights, [:flight_number, :departure_at]
    add_index :flights, :status
    add_index :flights, :departure_at
    add_index :flights, :airline_code

    create_table :passenger_bookings do |t|
      t.string     :pnr_code, null: false
      t.references :user, null: false, foreign_key: true
      t.references :flight, null: false, foreign_key: true
      t.string     :cabin_class, null: false, default: "economy"
      t.decimal    :base_allowance_kg, precision: 5, scale: 2, null: false, default: 23.0
      t.decimal    :current_allowance_kg, precision: 5, scale: 2, null: false, default: 23.0
      t.decimal    :max_allowance_kg, precision: 5, scale: 2, null: false, default: 46.0

      t.timestamps
    end
    add_index :passenger_bookings, :pnr_code, unique: true
    add_index :passenger_bookings, [:user_id, :flight_id], unique: true

    create_table :kilo_orders do |t|
      t.references :flight, null: false, foreign_key: true
      t.references :passenger_booking, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string     :side, null: false
      t.decimal    :quantity_kg, precision: 5, scale: 2, null: false
      t.decimal    :remaining_kg, precision: 5, scale: 2, null: false
      t.integer    :price_per_kg_cents, null: false
      t.string     :payout_preference, null: false, default: "voucher"
      t.string     :status, null: false, default: "open"

      t.timestamps
    end
    add_index :kilo_orders, [:flight_id, :side, :status, :price_per_kg_cents, :created_at], name: "idx_kilo_orders_order_book"
    add_index :kilo_orders, [:user_id, :flight_id, :status], name: "idx_kilo_orders_user_flight_status"

    create_table :kilo_trades do |t|
      t.references :flight, null: false, foreign_key: true
      t.references :buy_order, null: false, foreign_key: { to_table: :kilo_orders }
      t.references :sell_order, null: false, foreign_key: { to_table: :kilo_orders }
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.decimal    :quantity_kg, precision: 5, scale: 2, null: false
      t.integer    :execution_price_per_kg_cents, null: false
      t.integer    :gross_amount_cents, null: false
      t.integer    :airline_fee_cents, null: false
      t.integer    :seller_payout_cents, null: false
      t.string     :payout_type, null: false, default: "voucher"
      t.integer    :estimated_fuel_cost_cents, null: false, default: 0
      t.integer    :airline_net_margin_cents, null: false, default: 0
      t.integer    :buyer_savings_cents, null: false, default: 0
      t.datetime   :executed_at, null: false

      t.timestamps
    end
    add_index :kilo_trades, [:flight_id, :executed_at]
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

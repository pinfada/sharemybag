class Flight < ApplicationRecord
  STATUSES = %w[open closed departed].freeze
  CUTOFF_HOURS_BEFORE_DEPARTURE = 4

  belongs_to :aircraft_type
  has_many :passenger_bookings, dependent: :destroy
  has_many :kilo_orders, dependent: :destroy
  has_many :kilo_trades, dependent: :destroy

  validates :flight_number, presence: true, length: { maximum: 16 }
  validates :airline_name, presence: true, length: { maximum: 80 }
  validates :airline_code, presence: true, length: { in: 2..3 }
  validates :departure_iata, :arrival_iata, presence: true, length: { is: 3 }
  validates :departure_city, :arrival_city, presence: true, length: { maximum: 80 }
  validates :departure_at, presence: true
  validates :flight_duration_hours, presence: true, numericality: { greater_than: 0.3, less_than_or_equal_to: 20 }
  validates :airport_excess_fee_per_kg_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :airline_commission_bps, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5000 }
  validates :base_booked_baggage_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate  :base_baggage_within_aircraft_payload

  scope :active_exchange, -> { where(status: "open").where("departure_at > ?", CUTOFF_HOURS_BEFORE_DEPARTURE.hours.from_now).order(departure_at: :asc) }
  scope :upcoming, -> { order(departure_at: :asc) }

  def trading_open?
    status == "open" && departure_at.present? && departure_at > CUTOFF_HOURS_BEFORE_DEPARTURE.hours.from_now
  end

  def trading_cutoff_at
    departure_at - CUTOFF_HOURS_BEFORE_DEPARTURE.hours
  end

  def hours_until_cutoff
    return 0.0 unless trading_open?
    ((trading_cutoff_at - Time.current) / 3600.0).round(1)
  end

  def commission_percent
    (airline_commission_bps.to_f / 100.0).round(2)
  end

  def route_label
    "#{departure_iata} → #{arrival_iata}"
  end

  def open_bids
    kilo_orders.active.where(side: "buy").order(price_per_kg_cents: :desc, created_at: :asc, id: :asc)
  end

  def open_asks
    kilo_orders.active.where(side: "sell").order(price_per_kg_cents: :asc, created_at: :asc, id: :asc)
  end

  def best_bid_cents
    open_bids.first&.price_per_kg_cents
  end

  def best_ask_cents
    open_asks.first&.price_per_kg_cents
  end

  def spread_cents
    return nil unless best_bid_cents && best_ask_cents
    best_ask_cents - best_bid_cents
  end

  def last_trade_price_cents
    kilo_trades.confirmed.order(executed_at: :desc, id: :desc).limit(1).pick(:execution_price_per_kg_cents)
  end

  def spot_price_cents
    return last_trade_price_cents if last_trade_price_cents.present?
    return ((best_bid_cents + best_ask_cents) / 2.0).round if best_bid_cents && best_ask_cents
    best_bid_cents || best_ask_cents
  end

  def total_demand_kg
    open_bids.sum(:remaining_kg).to_f.round(2)
  end

  def total_supply_kg
    open_asks.sum(:remaining_kg).to_f.round(2)
  end

  def total_matched_kg
    kilo_trades.confirmed.sum(:quantity_kg).to_f.round(2)
  end

  def current_total_baggage_kg
    # Tracks booked allowances. Actual baggage loaded can differ from the booked weight.
    pnr_delta = passenger_bookings.sum("current_allowance_kg - base_allowance_kg").to_f
    (base_booked_baggage_kg.to_f + pnr_delta).round(2)
  end

  def max_baggage_payload_kg
    aircraft_type.max_baggage_payload_kg.to_f
  end

  def remaining_payload_headroom_kg
    [max_baggage_payload_kg - current_total_baggage_kg, 0.0].max.round(2)
  end

  def payload_utilization_percent
    return 0.0 if max_baggage_payload_kg <= 0
    ((current_total_baggage_kg / max_baggage_payload_kg) * 100.0).clamp(0.0, 100.0).round(1)
  end

  def estimated_savings_percent_vs_airport
    spot = spot_price_cents
    return 0 unless spot && airport_excess_fee_per_kg_cents.to_i > 0
    (((airport_excess_fee_per_kg_cents - spot).to_f / airport_excess_fee_per_kg_cents) * 100.0).round
  end

  private

  def base_baggage_within_aircraft_payload
    return unless aircraft_type && base_booked_baggage_kg.present?
    if base_booked_baggage_kg.to_f > aircraft_type.max_baggage_payload_kg.to_f
      errors.add(:base_booked_baggage_kg, :exceeds_aircraft_payload)
    end
  end
end

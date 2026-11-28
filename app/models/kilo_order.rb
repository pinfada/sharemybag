class KiloOrder < ApplicationRecord
  SIDES = %w[buy sell].freeze
  STATUSES = %w[open partially_filled filled cancelled].freeze
  ACTIVE_STATUSES = %w[open partially_filled].freeze
  PAYOUT_PREFERENCES = %w[voucher cash].freeze

  belongs_to :flight
  belongs_to :passenger_booking
  belongs_to :user

  has_many :buy_trades, class_name: "KiloTrade", foreign_key: :buy_order_id, dependent: :restrict_with_error
  has_many :sell_trades, class_name: "KiloTrade", foreign_key: :sell_order_id, dependent: :restrict_with_error

  before_validation :initialize_remaining_kg, on: :create
  before_validation :normalize_payout_preference

  validates :side, inclusion: { in: SIDES }
  validates :status, inclusion: { in: STATUSES }
  validates :payout_preference, inclusion: { in: PAYOUT_PREFERENCES }
  validates :quantity_kg, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 23 }
  validates :remaining_kg, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :price_per_kg_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 100, less_than_or_equal_to: 5000 }

  validate :booking_matches_user_and_flight
  validate :flight_accepts_orders, on: :create
  validate :no_opposite_active_order_on_flight, on: :create
  validate :quantity_within_booking_limits, on: :create

  scope :active, -> { where(status: ACTIVE_STATUSES).where("remaining_kg > 0") }
  scope :recent, -> { order(created_at: :desc) }

  def price_per_kg_euros
    return nil if price_per_kg_cents.blank?
    price_per_kg_cents / 100.0
  end

  def price_per_kg_euros=(val)
    return if val.nil? || val.to_s.strip.empty?
    cleaned = val.to_s.tr(",", ".")
    self.price_per_kg_cents = (cleaned.to_f * 100).round
  end

  def buy?
    side == "buy"
  end

  def sell?
    side == "sell"
  end

  def active?
    ACTIVE_STATUSES.include?(status) && remaining_kg.to_f > 0
  end

  def filled_kg
    (quantity_kg.to_f - remaining_kg.to_f).round(2)
  end

  def estimated_gross_cents
    (quantity_kg.to_f * price_per_kg_cents.to_i).round
  end

  def cancel!
    flight.with_lock do
      reload
      next false unless active?

      update!(status: "cancelled", remaining_kg: 0.0)
    end
  end

  private

  def initialize_remaining_kg
    self.remaining_kg = quantity_kg if remaining_kg.nil? && quantity_kg.present?
  end

  def normalize_payout_preference
    self.payout_preference = "voucher" if payout_preference.blank?
  end

  def booking_matches_user_and_flight
    return unless passenger_booking && user && flight
    if passenger_booking.user_id != user.id || passenger_booking.flight_id != flight.id
      errors.add(:passenger_booking, :must_belong_to_user_and_flight)
    end
  end

  def flight_accepts_orders
    return unless flight
    unless flight.trading_open?
      errors.add(:base, :flight_trading_closed)
    end
  end

  def no_opposite_active_order_on_flight
    return unless user && flight && side.present?
    opposite = buy? ? "sell" : "buy"
    if passenger_booking&.pending_trade_kg(opposite)&.positive? ||
       KiloOrder.active.where(user_id: user.id, flight_id: flight.id, side: opposite).exists?
      errors.add(:base, :opposite_order_already_open)
    end
  end

  def quantity_within_booking_limits
    return unless passenger_booking && quantity_kg.present? && side.present?
    qty = quantity_kg.to_f
    if sell? && qty > passenger_booking.available_to_sell_kg
      errors.add(:quantity_kg, :exceeds_available_to_sell, max: passenger_booking.available_to_sell_kg)
    elsif buy? && qty > passenger_booking.available_to_buy_kg
      errors.add(:quantity_kg, :exceeds_available_to_buy, max: passenger_booking.available_to_buy_kg)
    end
  end
end

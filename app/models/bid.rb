class Bid < ApplicationRecord
  class InvalidTransitionError < StandardError; end

  STATUSES = %w[pending accepted rejected withdrawn].freeze

  belongs_to :shipping_request
  belongs_to :traveler, class_name: "User"

  validates :price_per_kg_cents, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100_000 }
  validates :available_kg, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50 }
  validates :travel_date, presence: true
  validates :currency, presence: true, inclusion: { in: ShippingRequest::CURRENCIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :flight_number, length: { maximum: 20 }, allow_blank: true
  validates :message, length: { maximum: 1000 }, allow_blank: true
  validates :traveler_id, uniqueness: { scope: :shipping_request_id, message: :already_bid }

  validate :cannot_bid_own_request, on: :create
  validate :travel_date_in_future, on: :create
  validate :shipping_request_must_be_biddable, on: :create
  validate :available_kg_covers_request, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  def price_per_kg_euros
    return nil if price_per_kg_cents.nil?
    (price_per_kg_cents / 100.0).round(2)
  end

  def price_per_kg_euros=(value)
    if value.blank?
      self.price_per_kg_cents = nil
    else
      normalized = value.to_s.tr(',', '.').strip
      self.price_per_kg_cents = (BigDecimal(normalized) * 100).round.to_i
    end
  rescue ArgumentError
    self.price_per_kg_cents = -1
  end

  def price_per_kg
    price_per_kg_cents.to_f / 100.0
  end

  def total_price_cents
    return 0 unless price_per_kg_cents && shipping_request&.weight_kg
    (price_per_kg_cents * shipping_request.weight_kg).round
  end

  def total_price
    total_price_cents / 100.0
  end

  def withdrawable?
    status == "pending"
  end

  def withdraw!
    ActiveRecord::Base.transaction do
      lock!
      raise InvalidTransitionError, "Only a pending offer can be withdrawn." unless withdrawable?
      update!(status: "withdrawn")
    end
  end

  private

  def cannot_bid_own_request
    if traveler_id.present? && traveler_id == shipping_request&.sender_id
      errors.add(:base, :cannot_bid_own_request)
    end
  end

  def travel_date_in_future
    if travel_date.present? && travel_date < Date.current
      errors.add(:travel_date, :in_the_past)
    end
  end

  def shipping_request_must_be_biddable
    unless shipping_request&.open_for_bids?
      errors.add(:base, :request_closed)
    end
  end

  def available_kg_covers_request
    if available_kg.present? && shipping_request&.weight_kg.present? && available_kg < shipping_request.weight_kg
      errors.add(:available_kg, :insufficient_capacity, min: shipping_request.weight_kg)
    end
  end
end

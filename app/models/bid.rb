class Bid < ActiveRecord::Base
  belongs_to :shipping_request
  belongs_to :traveler, class_name: "User"
  belongs_to :kilo_offer, optional: true

  validates :price_per_kg_cents, presence: true, numericality: { greater_than: 0 }
  validates :available_kg, presence: true, numericality: { greater_than: 0 }
  validates :travel_date, presence: true
  validates :currency, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending accepted rejected withdrawn] }
  validates :traveler_id, uniqueness: { scope: :shipping_request_id, message: "has already bid on this request" }

  validate :cannot_bid_own_request, on: :create
  validate :travel_date_in_future, on: :create
  validate :shipping_request_must_be_biddable, on: :create
  validate :available_kg_covers_request, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  def price_per_kg
    price_per_kg_cents / 100.0
  end

  def total_price_cents
    (price_per_kg_cents * shipping_request.weight_kg).round
  end

  private

  def cannot_bid_own_request
    if traveler_id == shipping_request&.sender_id
      errors.add(:base, "You cannot bid on your own shipping request")
    end
  end

  def travel_date_in_future
    if travel_date.present? && travel_date < Date.today
      errors.add(:travel_date, "must be in the future")
    end
  end

  def shipping_request_must_be_biddable
    unless shipping_request&.status&.in?(%w[open bidding])
      errors.add(:base, "This request is no longer accepting bids")
    end
  end

  def available_kg_covers_request
    if available_kg.present? && shipping_request&.weight_kg.present? && available_kg < shipping_request.weight_kg
      errors.add(:available_kg, "must be at least #{shipping_request.weight_kg} kg to cover this request")
    end
  end
end

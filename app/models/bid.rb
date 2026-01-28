class Bid < ActiveRecord::Base
  belongs_to :shipping_request
  belongs_to :traveler, class_name: "User"
  belongs_to :kilo_offer, optional: true

  validates :price_per_kg_cents, presence: true, numericality: { greater_than: 0 }
  validates :available_kg, presence: true, numericality: { greater_than: 0 }
  validates :travel_date, presence: true
  validates :currency, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending accepted rejected withdrawn] }

  validate :cannot_bid_own_request
  validate :travel_date_in_future, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  def price_per_kg
    price_per_kg_cents / 100.0
  end

  def total_price_cents
    (price_per_kg_cents * shipping_request.weight_kg).to_i
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
end

class KiloOffer < ActiveRecord::Base
  belongs_to :traveler, class_name: "User"
  belongs_to :vol, optional: true
  has_many :bids, dependent: :nullify

  validates :departure_city, :departure_country, :arrival_city, :arrival_country, presence: true
  validates :travel_date, presence: true
  validates :available_kg, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50 }
  validates :price_per_kg_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: %w[EUR USD GBP XOF XAF] }
  validates :status, presence: true, inclusion: { in: %w[active booked completed expired] }

  validate :travel_date_in_future, on: :create

  scope :active, -> { where(status: "active") }
  scope :by_route, ->(from, to) { where(departure_city: from, arrival_city: to) }
  scope :by_date, ->(date) { where("travel_date >= ?", date) }
  scope :by_min_weight, ->(weight) { where("available_kg >= ?", weight) }
  scope :cheapest_first, -> { order(price_per_kg_cents: :asc) }

  def price_per_kg
    price_per_kg_cents / 100.0
  end

  private

  def travel_date_in_future
    if travel_date.present? && travel_date < Date.today
      errors.add(:travel_date, "must be in the future")
    end
  end
end

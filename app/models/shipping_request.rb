class ShippingRequest < ApplicationRecord
  class InvalidActionError < StandardError; end

  CATEGORIES = %w[documents clothing electronics books gifts other].freeze
  CURRENCIES = %w[EUR].freeze
  STATUSES = %w[open bidding accepted in_progress completed cancelled].freeze
  OPEN_STATUSES = %w[open bidding].freeze
  CUSTOMS_ALLOWANCE_CENTS = 43_000 # Standard €430 air-traveler duty-free allowance (EU benchmark)

  belongs_to :sender, class_name: "User"
  has_many :bids, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_one :shipment_tracking, dependent: :destroy

  validates :title, presence: true, length: { minimum: 4, maximum: 100 }
  validates :description, length: { maximum: 1500 }, allow_blank: true
  validates :special_instructions, length: { maximum: 500 }, allow_blank: true
  validates :weight_kg, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50 }
  validates :length_cm, :width_cm, :height_cm,
            numericality: { greater_than: 0, less_than_or_equal_to: 200 },
            allow_nil: true
  validates :departure_city, :departure_country, :arrival_city, :arrival_country,
            presence: true, length: { maximum: 80 }
  validates :desired_date, presence: true
  validates :currency, presence: true, inclusion: { in: CURRENCIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :item_category, inclusion: { in: CATEGORIES }, allow_blank: true
  validates :max_budget_cents, numericality: { greater_than: 0, less_than_or_equal_to: 500_000 }, allow_nil: true
  validates :declared_value_cents, numericality: { greater_than: 0, less_than_or_equal_to: 1_000_000 }, allow_nil: true
  validates :prohibited_items_acknowledged, acceptance: { accept: true }, on: :create

  validate :desired_date_in_future, on: :create
  validate :deadline_not_before_desired_date

  scope :open_for_bids, -> { where(status: OPEN_STATUSES) }
  scope :active, -> { open_for_bids.where("desired_date >= ?", Date.current) }
  scope :by_date, ->(date) { where("desired_date >= ?", date) }
  scope :by_max_weight, ->(weight) { where("weight_kg <= ?", weight) }
  scope :search_departure, ->(query) {
    where("LOWER(departure_city) LIKE :q OR LOWER(departure_country) LIKE :q",
          q: "%#{sanitize_sql_like(query.to_s.strip.downcase)}%")
  }
  scope :search_arrival, ->(query) {
    where("LOWER(arrival_city) LIKE :q OR LOWER(arrival_country) LIKE :q",
          q: "%#{sanitize_sql_like(query.to_s.strip.downcase)}%")
  }

  def max_budget_euros
    return nil if max_budget_cents.nil?
    (max_budget_cents / 100.0).round(2)
  end

  def max_budget_euros=(value)
    self.max_budget_cents = parse_euros_to_cents(value)
  end

  def declared_value_euros
    return nil if declared_value_cents.nil?
    (declared_value_cents / 100.0).round(2)
  end

  def declared_value_euros=(value)
    self.declared_value_cents = parse_euros_to_cents(value)
  end

  def international?
    departure_country.to_s.strip.downcase != arrival_country.to_s.strip.downcase
  end

  def above_customs_allowance?
    international? && declared_value_cents.to_i > CUSTOMS_ALLOWANCE_CENTS
  end

  def open_for_bids?
    OPEN_STATUSES.include?(status)
  end

  def editable?
    open_for_bids?
  end

  def cancellable?
    open_for_bids?
  end

  def accepted_bid
    bids.find_by(status: "accepted")
  end

  def pending_bids_count
    bids.where(status: "pending").count
  end

  def lowest_pending_bid
    bids.where(status: "pending").order(price_per_kg_cents: :asc).first
  end

  def accept_bid!(bid)
    ActiveRecord::Base.transaction do
      lock!
      bid.lock!

      unless open_for_bids?
        raise InvalidActionError, "This request is no longer accepting offers."
      end

      unless bid.shipping_request_id == id && bid.status == "pending"
        raise InvalidActionError, "This offer can no longer be accepted."
      end

      bid.update!(status: "accepted")
      bids.where(status: "pending").where.not(id: bid.id).update_all(status: "rejected", updated_at: Time.current)
      update!(status: "accepted")

      ShipmentTracking.create!(
        shipping_request: self,
        traveler: bid.traveler,
        status: "created"
      )
    end
  end

  def cancel!
    ActiveRecord::Base.transaction do
      lock!
      raise InvalidActionError, "An accepted shipping request cannot be cancelled." unless cancellable?

      bids.where(status: "pending").update_all(status: "rejected", updated_at: Time.current)
      update!(status: "cancelled")
    end
  end

  private

  def parse_euros_to_cents(value)
    return nil if value.blank?
    normalized = value.to_s.tr(',', '.').strip
    (BigDecimal(normalized) * 100).round.to_i
  rescue ArgumentError
    -1
  end

  def desired_date_in_future
    if desired_date.present? && desired_date < Date.current
      errors.add(:desired_date, :in_the_past)
    end
  end

  def deadline_not_before_desired_date
    if desired_date.present? && deadline_date.present? && deadline_date < desired_date
      errors.add(:deadline_date, :before_desired_date)
    end
  end
end

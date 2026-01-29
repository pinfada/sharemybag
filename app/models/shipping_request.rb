class ShippingRequest < ActiveRecord::Base
  belongs_to :sender, class_name: "User"
  has_many :bids, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_one :shipment_tracking, dependent: :destroy
  has_one :transaction, dependent: :destroy
  has_many :disputes, dependent: :destroy
  has_one :customs_declaration, dependent: :destroy
  has_one :compliance_checklist, dependent: :destroy
  has_many :security_screenings, dependent: :destroy

  def contains_dangerous_goods?
    contains_dangerous_goods == true
  end

  def compliance_cleared?
    compliance_status == "cleared"
  end

  validates :title, presence: true, length: { maximum: 100 }
  validates :weight_kg, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50 }
  validates :departure_city, :departure_country, :arrival_city, :arrival_country, presence: true
  validates :desired_date, presence: true
  validates :currency, presence: true, inclusion: { in: %w[EUR USD GBP XOF XAF] }
  validates :status, presence: true, inclusion: { in: %w[open bidding accepted in_progress completed cancelled] }

  validate :desired_date_in_future, on: :create

  scope :open, -> { where(status: "open") }
  scope :active, -> { where(status: %w[open bidding]).where("desired_date >= ?", Date.today) }
  scope :by_route, ->(from, to) { where(departure_city: from, arrival_city: to) }
  scope :by_date, ->(date) { where("desired_date >= ?", date) }
  scope :by_max_weight, ->(weight) { where("weight_kg <= ?", weight) }

  def accepted_bid
    bids.find_by(status: "accepted")
  end

  def accept_bid!(bid)
    ActiveRecord::Base.transaction do
      bid.update!(status: "accepted")
      bids.where.not(id: bid.id).update_all(status: "rejected")
      update!(status: "accepted")
    end
  end

  private

  def desired_date_in_future
    if desired_date.present? && desired_date < Date.today
      errors.add(:desired_date, "must be in the future")
    end
  end
end

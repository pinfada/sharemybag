class FlightVerification < ActiveRecord::Base
  belongs_to :kilo_offer
  belongs_to :user

  STATUSES = %w[pending verified rejected expired manual_review].freeze

  validates :flight_number, presence: true, format: { with: /\A[A-Z]{2}\d{1,4}\z/i, message: "must be a valid flight number (e.g., AF1234)" }
  validates :departure_airport, presence: true
  validates :arrival_airport, presence: true
  validates :departure_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :verified, -> { where(status: 'verified') }
  scope :pending, -> { where(status: 'pending') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :for_user, ->(user) { where(user: user) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :with_fraud_flags, -> { where("fraud_flags != '[]'::jsonb") }

  def verified?
    status == 'verified'
  end

  def expired?
    departure_date < Date.current
  end

  def fraud_detected?
    fraud_flags.present? && fraud_flags.any?
  end
end

class ShipmentTracking < ActiveRecord::Base
  belongs_to :shipping_request
  belongs_to :traveler, class_name: "User"

  STATUSES = %w[created paid handed_over in_transit delivered confirmed disputed].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :handover_code, uniqueness: true, allow_nil: true
  validates :delivery_code, uniqueness: true, allow_nil: true

  before_create :generate_codes

  scope :active, -> { where.not(status: %w[confirmed disputed]) }

  def hand_over!
    update!(status: "handed_over", handed_over_at: Time.current)
  end

  def mark_in_transit!
    update!(status: "in_transit", in_transit_at: Time.current)
  end

  def deliver!
    update!(status: "delivered", delivered_at: Time.current)
  end

  def confirm!
    update!(status: "confirmed", confirmed_at: Time.current)
  end

  def status_timeline
    STATUSES.map do |s|
      {
        status: s,
        reached: STATUSES.index(status) >= STATUSES.index(s),
        timestamp: send("#{timeline_field(s)}")
      }
    end
  end

  private

  def generate_codes
    self.handover_code = SecureRandom.alphanumeric(8).upcase
    self.delivery_code = SecureRandom.alphanumeric(8).upcase
  end

  def timeline_field(s)
    case s
    when "handed_over" then "handed_over_at"
    when "in_transit" then "in_transit_at"
    when "delivered" then "delivered_at"
    when "confirmed" then "confirmed_at"
    else "created_at"
    end
  end
end

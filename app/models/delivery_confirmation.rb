class DeliveryConfirmation < ActiveRecord::Base
  belongs_to :shipment_tracking
  belongs_to :sender, class_name: "User"
  belongs_to :traveler, class_name: "User"

  validates :otp_digest, presence: true
  validates :otp_generated_at, presence: true
  validates :otp_expires_at, presence: true
  validates :shipment_tracking_id, uniqueness: true

  scope :active, -> { where(blocked: false).where("otp_expires_at > ?", Time.current) }
  scope :blocked, -> { where(blocked: true) }
  scope :expired, -> { where("otp_expires_at <= ?", Time.current) }

  def expired?
    otp_expires_at < Time.current
  end

  def blocked?
    blocked
  end

  def attempts_remaining
    [max_attempts - attempts_count, 0].max
  end

  def can_verify?
    !blocked? && !expired? && attempts_remaining > 0
  end
end

class ShipmentTracking < ApplicationRecord
  class InvalidTransitionError < StandardError; end

  STATUSES = %w[created handed_over in_transit delivered confirmed].freeze
  CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".chars.freeze

  belongs_to :shipping_request
  belongs_to :traveler, class_name: "User"

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :shipping_request_id, uniqueness: true
  validates :handover_code, uniqueness: true, allow_nil: true
  validates :delivery_code, uniqueness: true, allow_nil: true

  before_create :generate_codes

  scope :active, -> { where.not(status: "confirmed") }

  def participant?(user)
    return false unless user
    user.id == shipping_request.sender_id || user.id == traveler_id
  end

  def sender?(user)
    user.present? && user.id == shipping_request.sender_id
  end

  def traveler?(user)
    user.present? && user.id == traveler_id
  end

  def verify_and_hand_over!(submitted_code, open_inspection_confirmed: true)
    ActiveRecord::Base.transaction do
      lock!
      raise InvalidTransitionError, "Handover is not allowed in the current state." unless status == "created"
      return false unless open_inspection_confirmed
      return false unless secure_code_match?(submitted_code, handover_code)

      now = Time.current
      update!(status: "handed_over", handed_over_at: now, open_inspection_confirmed_at: now)
      shipping_request.update!(status: "in_progress")
      true
    end
  end

  def mark_in_transit!
    ActiveRecord::Base.transaction do
      lock!
      raise InvalidTransitionError, "The parcel must be handed over before marking it in transit." unless status == "handed_over"

      update!(status: "in_transit", in_transit_at: Time.current)
    end
  end

  def verify_and_deliver!(submitted_code)
    ActiveRecord::Base.transaction do
      lock!
      raise InvalidTransitionError, "Delivery can only be verified once the parcel is in transit." unless status == "in_transit"
      return false unless secure_code_match?(submitted_code, delivery_code)

      update!(status: "delivered", delivered_at: Time.current)
      true
    end
  end

  def confirm!
    ActiveRecord::Base.transaction do
      lock!
      raise InvalidTransitionError, "Receipt can only be confirmed after delivery is verified." unless status == "delivered"

      update!(status: "confirmed", confirmed_at: Time.current)
      shipping_request.update!(status: "completed")
    end
  end

  def status_timeline
    current_index = STATUSES.index(status) || 0
    STATUSES.each_with_index.map do |step_status, idx|
      {
        status: step_status,
        reached: current_index >= idx,
        current: current_index == idx,
        timestamp: timestamp_for(step_status)
      }
    end
  end

  private

  def secure_code_match?(submitted, expected)
    normalized = submitted.to_s.strip.upcase
    return false if normalized.blank? || expected.blank?
    return false unless normalized.bytesize == expected.bytesize

    ActiveSupport::SecurityUtils.secure_compare(normalized, expected)
  end

  def generate_codes
    self.handover_code = generate_unique_code(:handover_code)
    loop do
      candidate = generate_unique_code(:delivery_code)
      if candidate != handover_code
        self.delivery_code = candidate
        break
      end
    end
  end

  def generate_unique_code(column)
    loop do
      code = Array.new(8) { CODE_ALPHABET[SecureRandom.random_number(CODE_ALPHABET.length)] }.join
      return code unless self.class.exists?(column => code)
    end
  end

  def timestamp_for(step_status)
    case step_status
    when "created"     then created_at
    when "handed_over" then handed_over_at
    when "in_transit"  then in_transit_at
    when "delivered"   then delivered_at
    when "confirmed"   then confirmed_at
    end
  end
end

class Review < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "User"
  belongs_to :shipping_request

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 1000 }, allow_blank: true
  validates :role, presence: true, inclusion: { in: %w[sender traveler] }
  validates :reviewer_id, uniqueness: { scope: :shipping_request_id, message: :already_reviewed }

  validate :cannot_review_self
  validate :shipment_must_be_completed
  validate :participants_must_match_shipment

  scope :recent, -> { order(created_at: :desc) }

  private

  def cannot_review_self
    if reviewer_id.present? && reviewer_id == reviewee_id
      errors.add(:base, :cannot_review_self)
    end
  end

  def shipment_must_be_completed
    tracking = shipping_request&.shipment_tracking
    completed = shipping_request&.status == "completed" || tracking&.status == "confirmed"
    unless completed
      errors.add(:base, :shipment_not_completed)
    end
  end

  def participants_must_match_shipment
    return unless shipping_request && reviewer_id.present? && reviewee_id.present?

    accepted_bid = shipping_request.accepted_bid
    return errors.add(:base, :no_accepted_bid) unless accepted_bid

    sender_id = shipping_request.sender_id
    traveler_id = accepted_bid.traveler_id

    valid_pair = (reviewer_id == sender_id && reviewee_id == traveler_id && role == "sender") ||
                 (reviewer_id == traveler_id && reviewee_id == sender_id && role == "traveler")

    errors.add(:base, :invalid_participants) unless valid_pair
  end
end

class Review < ActiveRecord::Base
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "User"
  belongs_to :shipping_request

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 1000 }
  validates :role, presence: true, inclusion: { in: %w[sender traveler] }
  validates :reviewer_id, uniqueness: { scope: :shipping_request_id, message: "has already reviewed this transaction" }

  validate :cannot_review_self
  validate :transaction_must_be_completed

  scope :recent, -> { order(created_at: :desc) }
  scope :positive, -> { where("rating >= 4") }

  private

  def cannot_review_self
    if reviewer_id == reviewee_id
      errors.add(:base, "You cannot review yourself")
    end
  end

  def transaction_must_be_completed
    unless shipping_request&.status == "completed"
      errors.add(:base, "Can only review completed transactions")
    end
  end
end

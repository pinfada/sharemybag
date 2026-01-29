class StripeWebhookEvent < ActiveRecord::Base
  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :payload, presence: true

  scope :processed, -> { where(processed: true) }
  scope :unprocessed, -> { where(processed: false) }
  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :by_type, ->(type) { where(event_type: type) }
end

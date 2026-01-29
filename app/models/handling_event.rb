class HandlingEvent < ActiveRecord::Base
  belongs_to :shipment_tracking
  belongs_to :actor, class_name: "User", optional: true

  EVENT_TYPES = %w[
    pickup security_check airport_checkin loaded unloaded
    customs_cleared in_transit arrived handoff delivery
    inspection seal_applied seal_verified photo_documented
  ].freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :content_hash, presence: true, uniqueness: true

  before_validation :compute_content_hash, on: :create
  before_validation :set_chain_hash, on: :create

  scope :chronological, -> { order(created_at: :asc) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :with_anomalies, -> { where(anomaly_detected: true) }
  scope :with_photos, -> { where.not(photo_url: nil) }
  scope :with_seals, -> { where.not(seal_number: nil) }

  def verified?
    computed = compute_hash_from_data
    computed == content_hash
  end

  def chain_valid?
    return true unless previous_event_hash.present?
    previous = shipment_tracking.handling_events.where("created_at < ?", created_at).order(created_at: :desc).first
    previous&.content_hash == previous_event_hash
  end

  def self.verify_chain(shipment_tracking)
    events = shipment_tracking.handling_events.chronological
    return { valid: true, events: 0 } if events.empty?

    broken_links = []
    events.each_cons(2) do |prev_event, curr_event|
      unless curr_event.previous_event_hash == prev_event.content_hash
        broken_links << { event_id: curr_event.id, expected: prev_event.content_hash, got: curr_event.previous_event_hash }
      end
    end

    { valid: broken_links.empty?, events: events.count, broken_links: broken_links }
  end

  private

  def compute_content_hash
    self.content_hash = compute_hash_from_data
  end

  def compute_hash_from_data
    data = "#{shipment_tracking_id}:#{event_type}:#{location}:#{latitude}:#{longitude}:" \
           "#{seal_number}:#{barcode_scanned}:#{notes}:#{created_at&.iso8601 || Time.current.iso8601}"
    Digest::SHA256.hexdigest(data)
  end

  def set_chain_hash
    previous = shipment_tracking&.handling_events&.order(created_at: :desc)&.first
    self.previous_event_hash = previous&.content_hash
  end
end

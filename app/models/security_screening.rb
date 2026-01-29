class SecurityScreening < ActiveRecord::Base
  belongs_to :user
  belongs_to :shipping_request, optional: true

  SCREENING_TYPES = %w[ofac sanctions pep watchlist aml].freeze
  STATUSES = %w[pending cleared flagged blocked].freeze
  SANCTIONS_LISTS = %w[OFAC_SDN UN_SANCTIONS EU_SANCTIONS UK_SANCTIONS INTERPOL].freeze

  validates :screening_type, presence: true, inclusion: { in: SCREENING_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :cleared, -> { where(status: "cleared") }
  scope :flagged, -> { where(status: %w[flagged blocked]) }
  scope :for_type, ->(type) { where(screening_type: type) }
  scope :recent_for_user, ->(user) { where(user: user).where("created_at > ?", 30.days.ago) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def cleared?
    status == "cleared" && !expired?
  end

  def requires_manual_review?
    status == "flagged" && !false_positive
  end
end

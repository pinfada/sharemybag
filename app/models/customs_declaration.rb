class CustomsDeclaration < ActiveRecord::Base
  belongs_to :shipping_request
  belongs_to :declared_by, class_name: "User"

  PURPOSES = %w[personal commercial gift sample repair return].freeze
  STATUSES = %w[pending validated flagged rejected].freeze

  validates :declaration_number, presence: true, uniqueness: true
  validates :origin_country, presence: true
  validates :destination_country, presence: true
  validates :total_declared_value_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :purpose, presence: true, inclusion: { in: PURPOSES }
  validates :item_descriptions, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :sender_attestation, acceptance: { accept: true, message: "must be accepted" }, on: :create

  before_validation :generate_declaration_number, on: :create

  scope :pending, -> { where(status: "pending") }
  scope :flagged, -> { where(status: "flagged") }
  scope :validated, -> { where(status: "validated") }

  # Customs thresholds by country (in EUR cents)
  DUTY_FREE_THRESHOLDS = {
    "FR" => 15000, "DE" => 15000, "US" => 80000, "GB" => 13500,
    "CA" => 2000, "SN" => 5000, "CI" => 5000, "CM" => 5000
  }.freeze

  def exceeds_duty_free_threshold?
    threshold = DUTY_FREE_THRESHOLDS[destination_country] || 15000
    total_declared_value_cents > threshold
  end

  def requires_commercial_invoice?
    purpose == "commercial" || total_declared_value_cents > 200000
  end

  def parsed_items
    return [] unless item_descriptions.present?
    JSON.parse(item_descriptions) rescue []
  end

  private

  def generate_declaration_number
    self.declaration_number = "SMB-CD-#{SecureRandom.hex(6).upcase}"
  end
end

class Dispute < ActiveRecord::Base
  belongs_to :shipping_request
  belongs_to :payment_transaction, class_name: "Transaction", foreign_key: "transaction_id"
  belongs_to :opened_by, class_name: "User"
  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  has_many :dispute_evidences, dependent: :destroy
  has_many :dispute_messages, dependent: :destroy

  STATUSES = %w[opened under_review evidence_requested escalated mediation resolved closed rejected].freeze
  TYPES = %w[non_delivered damaged wrong_content excessive_delay other].freeze
  PRIORITIES = %w[low normal high urgent].freeze
  RESOLUTION_TYPES = %w[full_refund partial_refund no_refund compensation rejected].freeze

  validates :dispute_type, presence: true, inclusion: { in: TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 5000 }

  scope :active, -> { where.not(status: %w[resolved closed rejected]) }
  scope :escalated, -> { where(status: 'escalated') }
  scope :overdue, -> { active.where("auto_escalate_at <= ?", Time.current) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :recent, -> { order(created_at: :desc) }

  def active?
    !status.in?(%w[resolved closed rejected])
  end

  def can_add_evidence?
    active?
  end

  def resolution_display
    case resolution_type
    when 'full_refund' then "Full refund"
    when 'partial_refund' then "Partial refund (#{resolution_amount_cents.to_i / 100.0} #{resolution_currency})"
    when 'no_refund' then "No refund - resolved in traveler's favor"
    when 'compensation' then "Compensation (#{resolution_amount_cents.to_i / 100.0} #{resolution_currency})"
    when 'rejected' then "Dispute rejected"
    end
  end

  def days_open
    ((resolved_at || Time.current) - created_at).to_i / 1.day
  end
end

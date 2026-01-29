class DisputeEvidence < ActiveRecord::Base
  belongs_to :dispute
  belongs_to :submitted_by, class_name: "User"

  EVIDENCE_TYPES = %w[photo video document message tracking_data].freeze

  validates :evidence_type, presence: true, inclusion: { in: EVIDENCE_TYPES }
  validates :content_hash, presence: true, if: :file_url?

  before_validation :compute_content_hash, if: :file_url_changed?

  scope :by_type, ->(type) { where(evidence_type: type) }
  scope :photos, -> { where(evidence_type: 'photo') }
  scope :documents, -> { where(evidence_type: 'document') }

  def immutable?
    content_hash.present?
  end

  private

  def compute_content_hash
    self.content_hash = Digest::SHA256.hexdigest(file_url) if file_url.present?
  end

  def file_url?
    file_url.present?
  end

  def file_url_changed?
    respond_to?(:will_save_change_to_file_url?) ? will_save_change_to_file_url? : true
  end
end

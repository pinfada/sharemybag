class IdentityVerification < ActiveRecord::Base
  belongs_to :user
  belongs_to :verified_by, class_name: "User", optional: true

  validates :document_type, presence: true, inclusion: { in: %w[passport id_card driver_license] }
  validates :status, presence: true, inclusion: { in: %w[pending under_review verified rejected] }

  scope :pending, -> { where(status: "pending") }
  scope :verified, -> { where(status: "verified") }

  def verify!(admin_user)
    update!(status: "verified", verified_at: Time.current, verified_by: admin_user)
  end

  def reject!(admin_user, reason)
    update!(status: "rejected", verified_by: admin_user, rejection_reason: reason)
  end
end

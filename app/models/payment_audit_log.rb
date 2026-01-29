class PaymentAuditLog < ActiveRecord::Base
  belongs_to :transaction, optional: true
  belongs_to :user, optional: true

  validates :action, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_transaction, ->(txn) { where(transaction: txn) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_action, ->(action) { where(action: action) }
end

class PaymentAuditLog < ActiveRecord::Base
  belongs_to :payment_transaction, class_name: "Transaction", foreign_key: "transaction_id", optional: true
  belongs_to :user, optional: true

  validates :action, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_transaction, ->(txn) { where(transaction_id: txn.id) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_action, ->(action) { where(action: action) }
end

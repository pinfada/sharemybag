class DcsSyncEvent < ApplicationRecord
  OPERATIONS = %w[
    issue_buyer_emd_a
    adjust_seller_allowance
    issue_seller_voucher_emd_s
    restore_seller_allowance
    void_buyer_emd_a
  ].freeze

  STATUSES = %w[pending synced failed compensated].freeze

  belongs_to :kilo_trade
  belongs_to :airline_connector

  validates :idempotency_key, presence: true, uniqueness: true
  validates :operation, inclusion: { in: OPERATIONS }
  validates :pnr_code, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc, id: :desc) }
end

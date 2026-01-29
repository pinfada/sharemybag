class Transaction < ActiveRecord::Base
  belongs_to :shipping_request
  belongs_to :bid
  belongs_to :sender, class_name: "User"
  belongs_to :traveler, class_name: "User"

  PLATFORM_FEE_RATE = 0.15

  has_many :payment_audit_logs, dependent: :destroy
  has_many :disputes, dependent: :destroy

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :platform_fee_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :traveler_payout_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending paid escrow released refunded disputed] }
  validates :shipping_request_id, uniqueness: { message: "already has a transaction" }
  validates :bid_id, uniqueness: { message: "already used for a transaction" }

  scope :pending, -> { where(status: "pending") }
  scope :in_escrow, -> { where(status: "escrow") }
  scope :completed, -> { where(status: "released") }

  def self.create_from_bid(bid)
    return nil unless bid.status == "accepted"
    return nil if exists?(shipping_request_id: bid.shipping_request_id)

    amount = bid.total_price_cents
    fee = (amount * PLATFORM_FEE_RATE).round
    payout = amount - fee

    create!(
      shipping_request: bid.shipping_request,
      bid: bid,
      sender: bid.shipping_request.sender,
      traveler: bid.traveler,
      amount_cents: amount,
      platform_fee_cents: fee,
      traveler_payout_cents: payout,
      currency: bid.currency,
      status: "pending"
    )
  end

  def amount
    amount_cents / 100.0
  end

  def platform_fee
    platform_fee_cents / 100.0
  end

  def traveler_payout
    traveler_payout_cents / 100.0
  end

  def pay!
    update!(status: "escrow", paid_at: Time.current)
  end

  def release!
    update!(status: "released", released_at: Time.current)
  end

  def refund!
    update!(status: "refunded", refunded_at: Time.current)
  end
end

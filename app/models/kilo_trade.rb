class KiloTrade < ApplicationRecord
  belongs_to :flight
  belongs_to :buy_order, class_name: "KiloOrder"
  belongs_to :sell_order, class_name: "KiloOrder"
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  validates :quantity_kg, presence: true, numericality: { greater_than: 0 }
  validates :execution_price_per_kg_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :gross_amount_cents, :airline_fee_cents, :seller_payout_cents,
            presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :payout_type, inclusion: { in: KiloOrder::PAYOUT_PREFERENCES }
  validates :executed_at, presence: true
  validate  :distinct_counterparties

  scope :recent, -> { order(executed_at: :desc, id: :desc) }

  private

  def distinct_counterparties
    if buyer_id.present? && buyer_id == seller_id
      errors.add(:base, "Buyer and seller must be distinct passengers.")
    end
  end
end

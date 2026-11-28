class PassengerBooking < ApplicationRecord
  IATA_MAX_SINGLE_BAG_KG = 32.0
  CABIN_CLASSES = %w[economy premium_economy business].freeze

  belongs_to :user
  belongs_to :flight
  has_many :kilo_orders, dependent: :destroy

  before_validation :normalize_pnr

  validates :pnr_code, presence: true, uniqueness: { case_sensitive: false }, length: { in: 5..10 }
  validates :user_id, uniqueness: { scope: :flight_id, message: :already_booked_on_flight }
  validates :cabin_class, inclusion: { in: CABIN_CLASSES }
  validates :base_allowance_kg, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 46 }
  validates :current_allowance_kg, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 46 }
  validates :max_allowance_kg, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 46 }
  validate  :current_within_max_allowance

  def committed_sell_kg
    kilo_orders.active.where(side: "sell").sum(:remaining_kg).to_f
  end

  def committed_buy_kg
    kilo_orders.active.where(side: "buy").sum(:remaining_kg).to_f
  end

  def pending_trade_kg(side)
    order_column = side == "buy" ? :buy_order_id : :sell_order_id
    KiloTrade.where(order_column => kilo_orders.select(:id))
             .where(deferred_settlement: true, dcs_sync_status: KiloTrade::UNRESOLVED_STATUSES)
             .sum(:quantity_kg)
  end

  def available_to_sell_kg
    [current_allowance_kg.to_f - committed_sell_kg - pending_trade_kg("sell"), 0.0].max.round(2)
  end

  def available_to_buy_kg
    [max_allowance_kg.to_f - current_allowance_kg.to_f - committed_buy_kg - pending_trade_kg("buy"), 0.0].max.round(2)
  end

  def net_traded_kg
    (current_allowance_kg.to_f - base_allowance_kg.to_f).round(2)
  end

  def requires_split_bags?
    current_allowance_kg.to_f > IATA_MAX_SINGLE_BAG_KG
  end

  private

  def normalize_pnr
    self.pnr_code = pnr_code.to_s.strip.upcase if pnr_code.present?
  end

  def current_within_max_allowance
    return unless current_allowance_kg.present? && max_allowance_kg.present?
    if current_allowance_kg.to_f > max_allowance_kg.to_f
      errors.add(:current_allowance_kg, :exceeds_max_allowance)
    end
  end
end

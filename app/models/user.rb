class User < ApplicationRecord
  ROLES = %w[passenger airline_admin].freeze

  has_many :passenger_bookings, dependent: :destroy
  has_many :booked_flights, through: :passenger_bookings, source: :flight
  has_many :kilo_orders, dependent: :destroy
  has_many :buy_trades, class_name: "KiloTrade", foreign_key: :buyer_id, dependent: :destroy
  has_many :sell_trades, class_name: "KiloTrade", foreign_key: :seller_id, dependent: :destroy
  has_many :notifications, dependent: :destroy

  before_validation :normalize_email
  before_create :assign_remember_token

  validates :name, presence: true, length: { minimum: 2, maximum: 60 }
  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/i
  validates :email, presence: true,
                    length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }
  validates :voucher_balance_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :city, :country, length: { maximum: 80 }, allow_blank: true

  has_secure_password
  validates :password,
            length: { minimum: 8 },
            format: {
              with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+\z/,
              message: :weak_password
            },
            if: :password_required?

  def self.new_remember_token
    SecureRandom.urlsafe_base64(48)
  end

  def self.digest(token)
    return nil if token.blank?
    Digest::SHA256.hexdigest(token.to_s)
  end

  def airline_admin?
    role == "airline_admin"
  end

  def voucher_balance_euros
    voucher_balance_cents.to_f / 100.0
  end

  def initials
    parts = name.to_s.strip.split(/\s+/)
    return "?" if parts.empty?
    parts.first(2).map { |p| p[0] }.join.upcase
  end

  def unread_notifications_count
    notifications.unread.count
  end

  def completed_trades_count
    KiloTrade.where("buyer_id = :uid OR seller_id = :uid", uid: id).count
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end

  def assign_remember_token
    self.remember_token = User.digest(User.new_remember_token)
  end

  def password_required?
    new_record? || password.present?
  end
end

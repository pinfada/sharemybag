class User < ApplicationRecord
  has_many :shipping_requests, foreign_key: "sender_id", dependent: :destroy
  has_many :bids, foreign_key: "traveler_id", dependent: :destroy
  has_many :shipment_trackings, foreign_key: "traveler_id", dependent: :destroy
  has_many :sent_messages, class_name: "Message", foreign_key: "sender_id", dependent: :destroy
  has_many :reviews_given, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy
  has_many :reviews_received, class_name: "Review", foreign_key: "reviewee_id", dependent: :destroy
  has_many :notifications, dependent: :destroy

  before_validation :normalize_email
  before_create :assign_remember_token

  validates :name, presence: true, length: { minimum: 2, maximum: 60 }
  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/i
  validates :email, presence: true,
                    length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
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

  def initials
    parts = name.to_s.strip.split(/\s+/)
    return "?" if parts.empty?
    parts.first(2).map { |p| p[0] }.join.upcase
  end

  def average_rating
    reviews_received.average(:rating)&.to_f&.round(1) || 0.0
  end

  def reviews_count
    reviews_received.count
  end

  def completed_shipments_count
    ShipmentTracking.where(status: "confirmed")
                    .joins(:shipping_request)
                    .where("shipping_requests.sender_id = :uid OR shipment_trackings.traveler_id = :uid", uid: id)
                    .count
  end

  def unread_notifications_count
    notifications.unread.count
  end

  def unread_messages_count
    Message.joins(:conversation)
           .where("conversations.sender_id = :uid OR conversations.recipient_id = :uid", uid: id)
           .where.not(sender_id: id)
           .unread
           .count
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

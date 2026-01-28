class User < ActiveRecord::Base
  belongs_to :vol
  has_many :bookings
  has_many :bagages
  has_many :paquets
  has_many :identities, class_name: "Identitie",
                        foreign_key: "uid",
                        dependent: :destroy
  has_many :microposts, dependent: :destroy
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed
  has_many :reverse_relationships, foreign_key: "followed_id",
                                   class_name:  "Relationship",
                                   dependent:   :destroy
  has_many :followers, through: :reverse_relationships, source: :follower

  # New associations for the marketplace
  has_many :shipping_requests, foreign_key: "sender_id", dependent: :destroy
  has_many :bids, foreign_key: "traveler_id", dependent: :destroy
  has_many :kilo_offers, foreign_key: "traveler_id", dependent: :destroy
  has_many :sent_messages, class_name: "Message", foreign_key: "sender_id", dependent: :destroy
  has_many :reviews_given, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy
  has_many :reviews_received, class_name: "Review", foreign_key: "reviewee_id", dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_one :identity_verification, dependent: :destroy

  before_save { self.email = email.downcase }
  before_create :create_remember_token

  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true,
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, length: { minimum: 8 },
                       format: {
                         with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+\z/,
                         message: "must include at least one lowercase letter, one uppercase letter, and one digit"
                       }
  accepts_nested_attributes_for :bagages

  def User.new_remember_token
    SecureRandom.urlsafe_base64(64)
  end

  def User.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def feed
    Micropost.from_users_followed_by(self)
  end

  def following?(other_user)
    relationships.find_by(followed_id: other_user.id)
  end

  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy
  end

  def verified?
    identity_verification&.status == "verified"
  end

  def average_rating
    reviews_received.average(:rating)&.round(1) || 0.0
  end

  def completed_transactions_count
    ShipmentTracking.where(status: "confirmed")
                    .joins(:shipping_request)
                    .where("shipping_requests.sender_id = ? OR shipment_trackings.traveler_id = ?", id, id)
                    .count
  end

  private

  def create_remember_token
    self.remember_token = User.digest(User.new_remember_token)
  end
end

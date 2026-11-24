class Conversation < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :shipping_request, optional: true
  has_many :messages, dependent: :destroy

  validates :sender_id, uniqueness: { scope: :recipient_id }
  validate :cannot_converse_with_self
  validate :unique_participant_pair, on: :create

  scope :involving, ->(user) {
    where("sender_id = :uid OR recipient_id = :uid", uid: user.id)
  }

  def self.between(user_a, user_b)
    where(
      "(sender_id = :a AND recipient_id = :b) OR (sender_id = :b AND recipient_id = :a)",
      a: user_a.id, b: user_b.id
    ).first
  end

  def participant?(user)
    return false unless user
    sender_id == user.id || recipient_id == user.id
  end

  def other_participant(user)
    sender_id == user.id ? recipient : sender
  end

  def unread_count(user)
    messages.where.not(sender_id: user.id).where(read: false).count
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  private

  def cannot_converse_with_self
    if sender_id.present? && sender_id == recipient_id
      errors.add(:recipient_id, :cannot_message_self)
    end
  end

  def unique_participant_pair
    return unless sender_id.present? && recipient_id.present?

    if Conversation.exists?(sender_id: recipient_id, recipient_id: sender_id)
      errors.add(:base, :conversation_already_exists)
    end
  end
end

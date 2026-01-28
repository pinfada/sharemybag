class Conversation < ActiveRecord::Base
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :shipping_request, optional: true
  has_many :messages, dependent: :destroy

  validates :sender_id, uniqueness: { scope: :recipient_id }

  scope :involving, ->(user) {
    where("sender_id = ? OR recipient_id = ?", user.id, user.id)
  }

  def other_participant(user)
    sender_id == user.id ? recipient : sender
  end

  def unread_count(user)
    messages.where.not(sender_id: user.id).where(read: false).count
  end

  def last_message
    messages.order(created_at: :desc).first
  end
end

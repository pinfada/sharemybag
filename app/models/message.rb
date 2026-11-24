class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 2000 }
  validate :sender_must_be_participant

  scope :unread, -> { where(read: false) }
  scope :chronological, -> { order(created_at: :asc) }

  after_create :update_conversation_timestamp

  def mark_as_read!
    update!(read: true) unless read?
  end

  private

  def sender_must_be_participant
    return unless conversation && sender

    unless conversation.participant?(sender)
      errors.add(:sender, :not_a_participant)
    end
  end

  def update_conversation_timestamp
    conversation.touch
  end
end

class Message < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 2000 }

  scope :unread, -> { where(read: false) }
  scope :chronological, -> { order(created_at: :asc) }

  after_create :update_conversation_timestamp

  def mark_as_read!
    update!(read: true) unless read?
  end

  private

  def update_conversation_timestamp
    conversation.touch
  end
end

class DisputeMessage < ActiveRecord::Base
  belongs_to :dispute
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 5000 }

  scope :public_messages, -> { where(is_internal: false) }
  scope :internal_notes, -> { where(is_internal: true) }
  scope :unread, -> { where(read: false) }
  scope :chronological, -> { order(created_at: :asc) }
end

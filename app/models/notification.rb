class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  validates :action, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  def mark_as_read!
    update!(read: true) unless read?
  end

  def self.notify(user, notifiable, action, message)
    create!(
      user: user,
      notifiable: notifiable,
      action: action,
      message: message
    )
  end
end

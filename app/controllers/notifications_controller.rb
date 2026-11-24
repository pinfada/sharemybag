class NotificationsController < ApplicationController
  before_action :signed_in_user

  def index
    @notifications = current_user.notifications.includes(:notifiable).recent
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!
    redirect_to notification_target_path(notification)
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    flash[:notice] = t('notifications.all_marked_read')
    redirect_to notifications_path
  end
end

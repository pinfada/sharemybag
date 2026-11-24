require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "creates an unread notification on a flight and marks it as read" do
    user = create_user
    flight = create_flight

    notif = Notification.notify(user, flight, "trade_executed", "8 kg matched on AF718")
    assert notif.persisted?
    assert_equal 1, user.notifications.unread.count

    notif.mark_as_read!
    assert_equal 0, user.notifications.unread.count
  end
end

require 'test_helper'

class NotificationTest < ActiveSupport::TestCase
  test "crée une notification non lue et la marque comme lue" do
    user = create_user
    req = create_shipping_request(sender: user)

    notif = Notification.notify(user, req, "new_bid", "Nouvelle offre reçue")
    assert notif.persisted?
    assert_equal 1, user.notifications.unread.count

    notif.mark_as_read!
    assert_equal 0, user.notifications.unread.count
  end
end

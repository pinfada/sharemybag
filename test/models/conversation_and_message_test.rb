require 'test_helper'

class ConversationAndMessageTest < ActiveSupport::TestCase
  test "trouve une conversation existante quel que soit l'ordre des participants" do
    u1 = create_user
    u2 = create_user
    conv = Conversation.create!(sender: u1, recipient: u2)

    assert_equal conv, Conversation.between(u1, u2)
    assert_equal conv, Conversation.between(u2, u1)
    assert_equal u2, conv.other_participant(u1)
    assert_equal u1, conv.other_participant(u2)
  end

  test "interdit une conversation avec soi-même" do
    u = create_user
    conv = Conversation.new(sender: u, recipient: u)
    assert_not conv.valid?
  end

  test "valide le contenu du message et compte les non-lus" do
    u1 = create_user
    u2 = create_user
    conv = Conversation.create!(sender: u1, recipient: u2)

    msg = conv.messages.create!(sender: u1, body: "Bonjour, à quelle heure à CDG ?")
    assert_equal 1, conv.unread_count(u2)
    assert_equal 0, conv.unread_count(u1)

    msg.mark_as_read!
    assert_equal 0, conv.unread_count(u2)
  end
end

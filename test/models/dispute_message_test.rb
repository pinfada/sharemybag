require 'test_helper'

class DisputeMessageTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    message = FactoryBot.build(:dispute_message)
    assert message.valid?
  end

  test "should require body" do
    message = FactoryBot.build(:dispute_message, body: nil)
    assert_not message.valid?
  end

  test "should enforce body max length" do
    message = FactoryBot.build(:dispute_message, body: "a" * 5001)
    assert_not message.valid?
  end

  test "scope public_messages should exclude internal notes" do
    public_msg = FactoryBot.create(:dispute_message, is_internal: false)
    internal = FactoryBot.create(:dispute_message, is_internal: true)

    assert_includes DisputeMessage.public_messages, public_msg
    assert_not_includes DisputeMessage.public_messages, internal
  end
end

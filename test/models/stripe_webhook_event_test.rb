require 'test_helper'

class StripeWebhookEventTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    event = FactoryBot.build(:stripe_webhook_event)
    assert event.valid?
  end

  test "should require stripe_event_id" do
    event = FactoryBot.build(:stripe_webhook_event, stripe_event_id: nil)
    assert_not event.valid?
  end

  test "should require unique stripe_event_id" do
    FactoryBot.create(:stripe_webhook_event, stripe_event_id: "evt_123")
    duplicate = FactoryBot.build(:stripe_webhook_event, stripe_event_id: "evt_123")
    assert_not duplicate.valid?
  end

  test "should require event_type" do
    event = FactoryBot.build(:stripe_webhook_event, event_type: nil)
    assert_not event.valid?
  end

  test "scope processed should return only processed events" do
    processed = FactoryBot.create(:stripe_webhook_event, processed: true)
    unprocessed = FactoryBot.create(:stripe_webhook_event, processed: false)

    assert_includes StripeWebhookEvent.processed, processed
    assert_not_includes StripeWebhookEvent.processed, unprocessed
  end
end

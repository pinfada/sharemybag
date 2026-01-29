require 'test_helper'

class HandlingEventTest < ActiveSupport::TestCase
  def setup
    @tracking = FactoryBot.create(:shipment_tracking)
  end

  test "should create valid handling event" do
    event = @tracking.handling_events.create!(
      event_type: "pickup",
      location: "Paris CDG Terminal 2E",
      notes: "Package collected from sender"
    )

    assert event.valid?
    assert event.content_hash.present?
  end

  test "should require event_type" do
    event = @tracking.handling_events.build(event_type: nil)
    assert_not event.valid?
  end

  test "should require valid event_type" do
    event = @tracking.handling_events.build(event_type: "invalid")
    assert_not event.valid?
  end

  test "should compute content_hash automatically" do
    event = @tracking.handling_events.create!(event_type: "security_check", location: "CDG")
    assert event.content_hash.present?
    assert_equal 64, event.content_hash.length # SHA256 hex length
  end

  test "should enforce content_hash uniqueness" do
    event1 = @tracking.handling_events.create!(event_type: "pickup", location: "CDG")
    event2 = @tracking.handling_events.build(event_type: "pickup", location: "CDG")
    event2.content_hash = event1.content_hash
    assert_not event2.valid?
  end

  test "should chain events with previous_event_hash" do
    event1 = @tracking.handling_events.create!(event_type: "pickup", location: "Paris")
    event2 = @tracking.handling_events.create!(event_type: "security_check", location: "CDG Airport")

    assert_equal event1.content_hash, event2.previous_event_hash
  end

  test "verify_chain should return valid for intact chain" do
    @tracking.handling_events.create!(event_type: "pickup", location: "Paris")
    @tracking.handling_events.create!(event_type: "security_check", location: "CDG")
    @tracking.handling_events.create!(event_type: "loaded", location: "CDG Gate B12")

    result = HandlingEvent.verify_chain(@tracking)
    assert result[:valid]
    assert_equal 3, result[:events]
  end

  test "verify_chain should return valid for empty chain" do
    result = HandlingEvent.verify_chain(@tracking)
    assert result[:valid]
    assert_equal 0, result[:events]
  end

  test "scope chronological should order by created_at" do
    event1 = @tracking.handling_events.create!(event_type: "pickup", location: "A")
    event2 = @tracking.handling_events.create!(event_type: "delivery", location: "B")

    events = @tracking.handling_events.chronological
    assert_equal event1, events.first
    assert_equal event2, events.last
  end

  test "scope with_anomalies should filter anomalous events" do
    normal = @tracking.handling_events.create!(event_type: "pickup", location: "A")
    anomaly = @tracking.handling_events.create!(event_type: "inspection", location: "B", anomaly_detected: true, anomaly_description: "Seal broken")

    results = @tracking.handling_events.with_anomalies
    assert_includes results, anomaly
    assert_not_includes results, normal
  end
end

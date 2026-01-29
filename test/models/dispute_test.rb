require 'test_helper'

class DisputeTest < ActiveSupport::TestCase
  def setup
    @dispute = FactoryBot.create(:dispute)
  end

  test "should be valid with valid attributes" do
    assert @dispute.valid?
  end

  test "should require dispute_type" do
    @dispute.dispute_type = nil
    assert_not @dispute.valid?
  end

  test "should require valid dispute_type" do
    @dispute.dispute_type = "invalid_type"
    assert_not @dispute.valid?
  end

  test "should require title" do
    @dispute.title = nil
    assert_not @dispute.valid?
  end

  test "should enforce title max length" do
    @dispute.title = "a" * 201
    assert_not @dispute.valid?
  end

  test "should require description" do
    @dispute.description = nil
    assert_not @dispute.valid?
  end

  test "should require valid status" do
    @dispute.status = "invalid_status"
    assert_not @dispute.valid?
  end

  test "should require valid priority" do
    @dispute.priority = "invalid_priority"
    assert_not @dispute.valid?
  end

  test "active? should return true for open disputes" do
    assert @dispute.active?
  end

  test "active? should return false for resolved disputes" do
    @dispute.status = "resolved"
    assert_not @dispute.active?
  end

  test "active? should return false for closed disputes" do
    @dispute.status = "closed"
    assert_not @dispute.active?
  end

  test "days_open should calculate correctly" do
    @dispute.update_column(:created_at, 5.days.ago)
    assert_equal 5, @dispute.days_open
  end

  test "resolution_display for full_refund" do
    @dispute.resolution_type = "full_refund"
    assert_equal "Full refund", @dispute.resolution_display
  end

  test "can_add_evidence? should be true when active" do
    assert @dispute.can_add_evidence?
  end

  test "can_add_evidence? should be false when resolved" do
    @dispute.status = "resolved"
    assert_not @dispute.can_add_evidence?
  end

  test "scope active should exclude resolved/closed/rejected" do
    resolved = FactoryBot.create(:dispute, status: "resolved")
    closed = FactoryBot.create(:dispute, status: "closed")
    active = FactoryBot.create(:dispute, status: "opened")

    results = Dispute.active
    assert_includes results, active
    assert_not_includes results, resolved
    assert_not_includes results, closed
  end

  test "scope overdue should return disputes past auto_escalate_at" do
    overdue = FactoryBot.create(:dispute, auto_escalate_at: 1.hour.ago)
    not_overdue = FactoryBot.create(:dispute, auto_escalate_at: 1.hour.from_now)

    results = Dispute.overdue
    assert_includes results, overdue
    assert_not_includes results, not_overdue
  end
end

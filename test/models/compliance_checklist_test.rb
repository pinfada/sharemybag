require 'test_helper'

class ComplianceChecklistTest < ActiveSupport::TestCase
  def setup
    @sender = FactoryBot.create(:marketplace_user)
    @shipping_request = FactoryBot.create(:shipping_request, sender: @sender)
    @checklist = ComplianceChecklist.create!(
      shipping_request: @shipping_request,
      completed_by: @sender
    )
  end

  test "should be valid" do
    assert @checklist.valid?
  end

  test "should enforce uniqueness of shipping_request" do
    duplicate = ComplianceChecklist.new(shipping_request: @shipping_request, completed_by: @sender)
    assert_not duplicate.valid?
  end

  test "compliance_percentage should start at 0" do
    assert_equal 0, @checklist.compliance_percentage
  end

  test "compliance_percentage should increase with checks" do
    total = ComplianceChecklist::SENDER_ATTESTATIONS.size +
            ComplianceChecklist::SECURITY_CHECKS.size +
            ComplianceChecklist::AIRLINE_CHECKS.size

    @checklist.update!(no_prohibited_items: true, no_dangerous_goods: true)
    expected = ((2.0 / total) * 100).round
    assert_equal expected, @checklist.compliance_percentage
  end

  test "fully_compliant? should return false when incomplete" do
    assert_not @checklist.fully_compliant?
  end

  test "fully_compliant? should return true when all checks pass" do
    attrs = {}
    (ComplianceChecklist::SENDER_ATTESTATIONS +
     ComplianceChecklist::SECURITY_CHECKS +
     ComplianceChecklist::AIRLINE_CHECKS).each { |a| attrs[a] = true }
    @checklist.update!(attrs)

    assert @checklist.fully_compliant?
  end

  test "all_sender_attestations_complete? should check all attestations" do
    assert_not @checklist.all_sender_attestations_complete?

    ComplianceChecklist::SENDER_ATTESTATIONS.each { |a| @checklist.send("#{a}=", true) }
    assert @checklist.all_sender_attestations_complete?
  end

  test "mark_complete! should set completed_at and ip" do
    @checklist.mark_complete!(ip_address: "192.168.1.1", user_agent: "TestBrowser")
    assert_not_nil @checklist.completed_at
    assert_equal "192.168.1.1", @checklist.completed_ip
    assert_equal "TestBrowser", @checklist.user_agent
  end
end

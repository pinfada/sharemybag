require 'test_helper'

class DeliveryConfirmationTest < ActiveSupport::TestCase
  def setup
    @confirmation = FactoryBot.create(:delivery_confirmation)
  end

  test "should be valid with valid attributes" do
    assert @confirmation.valid?
  end

  test "should require otp_digest" do
    @confirmation.otp_digest = nil
    assert_not @confirmation.valid?
  end

  test "should require otp_generated_at" do
    @confirmation.otp_generated_at = nil
    assert_not @confirmation.valid?
  end

  test "should require otp_expires_at" do
    @confirmation.otp_expires_at = nil
    assert_not @confirmation.valid?
  end

  test "expired? should return false when OTP is still valid" do
    assert_not @confirmation.expired?
  end

  test "expired? should return true when OTP has expired" do
    @confirmation.otp_expires_at = 1.minute.ago
    assert @confirmation.expired?
  end

  test "blocked? should return true when blocked" do
    @confirmation.blocked = true
    assert @confirmation.blocked?
  end

  test "blocked? should return false when not blocked" do
    assert_not @confirmation.blocked?
  end

  test "attempts_remaining should calculate correctly" do
    assert_equal 3, @confirmation.attempts_remaining
    @confirmation.attempts_count = 2
    assert_equal 1, @confirmation.attempts_remaining
    @confirmation.attempts_count = 3
    assert_equal 0, @confirmation.attempts_remaining
  end

  test "can_verify? should return true when conditions are met" do
    assert @confirmation.can_verify?
  end

  test "can_verify? should return false when blocked" do
    @confirmation.blocked = true
    assert_not @confirmation.can_verify?
  end

  test "can_verify? should return false when expired" do
    @confirmation.otp_expires_at = 1.minute.ago
    assert_not @confirmation.can_verify?
  end

  test "can_verify? should return false when no attempts remaining" do
    @confirmation.attempts_count = 3
    assert_not @confirmation.can_verify?
  end

  test "should enforce uniqueness of shipment_tracking_id" do
    duplicate = FactoryBot.build(:delivery_confirmation, shipment_tracking: @confirmation.shipment_tracking)
    assert_not duplicate.valid?
  end
end

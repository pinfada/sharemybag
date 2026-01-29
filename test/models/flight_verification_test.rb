require 'test_helper'

class FlightVerificationTest < ActiveSupport::TestCase
  def setup
    @verification = FactoryBot.create(:flight_verification)
  end

  test "should be valid with valid attributes" do
    assert @verification.valid?
  end

  test "should require flight_number" do
    @verification.flight_number = nil
    assert_not @verification.valid?
  end

  test "should validate flight_number format" do
    @verification.flight_number = "INVALID"
    assert_not @verification.valid?
  end

  test "should accept valid flight numbers" do
    valid_numbers = %w[AF1234 BA456 LH1 AA9999]
    valid_numbers.each do |fn|
      @verification.flight_number = fn
      assert @verification.valid?, "#{fn} should be valid"
    end
  end

  test "should require departure_airport" do
    @verification.departure_airport = nil
    assert_not @verification.valid?
  end

  test "should require arrival_airport" do
    @verification.arrival_airport = nil
    assert_not @verification.valid?
  end

  test "should require departure_date" do
    @verification.departure_date = nil
    assert_not @verification.valid?
  end

  test "should require valid status" do
    @verification.status = "invalid"
    assert_not @verification.valid?
  end

  test "verified? should return true when status is verified" do
    @verification.status = "verified"
    assert @verification.verified?
  end

  test "verified? should return false when status is pending" do
    assert_not @verification.verified?
  end

  test "expired? should return true for past dates" do
    @verification.departure_date = 1.day.ago
    assert @verification.expired?
  end

  test "expired? should return false for future dates" do
    assert_not @verification.expired?
  end

  test "fraud_detected? should return true with flags" do
    @verification.fraud_flags = ["multiple_rejections"]
    assert @verification.fraud_detected?
  end

  test "fraud_detected? should return false without flags" do
    @verification.fraud_flags = []
    assert_not @verification.fraud_detected?
  end

  test "scope verified should return only verified records" do
    verified = FactoryBot.create(:flight_verification, status: "verified")
    pending = FactoryBot.create(:flight_verification, status: "pending")

    results = FlightVerification.verified
    assert_includes results, verified
    assert_not_includes results, pending
  end
end

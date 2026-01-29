require 'test_helper'

class ShippingRequestTest < ActiveSupport::TestCase
  def setup
    @sender = FactoryBot.create(:marketplace_user)
    @shipping_request = FactoryBot.create(:shipping_request, sender: @sender)
  end

  test "should be valid with valid attributes" do
    assert @shipping_request.valid?
  end

  test "should require title" do
    @shipping_request.title = nil
    assert_not @shipping_request.valid?
  end

  test "should enforce title max length" do
    @shipping_request.title = "a" * 101
    assert_not @shipping_request.valid?
  end

  test "should require weight_kg" do
    @shipping_request.weight_kg = nil
    assert_not @shipping_request.valid?
  end

  test "should not allow weight above 50kg" do
    @shipping_request.weight_kg = 51
    assert_not @shipping_request.valid?
  end

  test "should not allow negative weight" do
    @shipping_request.weight_kg = -1
    assert_not @shipping_request.valid?
  end

  test "should require departure_city" do
    @shipping_request.departure_city = nil
    assert_not @shipping_request.valid?
  end

  test "should require arrival_city" do
    @shipping_request.arrival_city = nil
    assert_not @shipping_request.valid?
  end

  test "should require desired_date" do
    @shipping_request.desired_date = nil
    assert_not @shipping_request.valid?
  end

  test "should require valid currency" do
    @shipping_request.currency = "INVALID"
    assert_not @shipping_request.valid?
  end

  test "should accept all valid currencies" do
    %w[EUR USD GBP XOF XAF].each do |currency|
      @shipping_request.currency = currency
      assert @shipping_request.valid?, "#{currency} should be valid"
    end
  end

  test "should require valid status" do
    @shipping_request.status = "invalid"
    assert_not @shipping_request.valid?
  end

  test "accept_bid! should accept bid and reject others" do
    traveler1 = FactoryBot.create(:marketplace_user)
    traveler2 = FactoryBot.create(:marketplace_user)
    bid1 = FactoryBot.create(:bid, shipping_request: @shipping_request, traveler: traveler1)
    bid2 = FactoryBot.create(:bid, shipping_request: @shipping_request, traveler: traveler2)

    @shipping_request.accept_bid!(bid1)

    assert_equal "accepted", bid1.reload.status
    assert_equal "rejected", bid2.reload.status
    assert_equal "accepted", @shipping_request.reload.status
  end

  test "accepted_bid should return accepted bid" do
    traveler = FactoryBot.create(:marketplace_user)
    bid = FactoryBot.create(:bid, shipping_request: @shipping_request, traveler: traveler, status: "accepted")

    assert_equal bid, @shipping_request.accepted_bid
  end

  test "scope open should return only open requests" do
    open_request = FactoryBot.create(:shipping_request, status: "open")
    accepted = FactoryBot.create(:shipping_request, status: "accepted")

    results = ShippingRequest.open
    assert_includes results, open_request
    assert_not_includes results, accepted
  end
end

require 'test_helper'

class BidTest < ActiveSupport::TestCase
  def setup
    @sender = FactoryBot.create(:marketplace_user)
    @traveler = FactoryBot.create(:marketplace_user)
    @shipping_request = FactoryBot.create(:shipping_request, sender: @sender, weight_kg: 5)
    @bid = FactoryBot.build(:bid, shipping_request: @shipping_request, traveler: @traveler)
  end

  test "should be valid with valid attributes" do
    assert @bid.valid?
  end

  test "should require price_per_kg_cents" do
    @bid.price_per_kg_cents = nil
    assert_not @bid.valid?
  end

  test "should not allow negative price" do
    @bid.price_per_kg_cents = -100
    assert_not @bid.valid?
  end

  test "should require available_kg" do
    @bid.available_kg = nil
    assert_not @bid.valid?
  end

  test "should require travel_date" do
    @bid.travel_date = nil
    assert_not @bid.valid?
  end

  test "should not allow bidding on own request" do
    @bid.traveler = @sender
    assert_not @bid.valid?
  end

  test "should not allow duplicate bids" do
    @bid.save!
    duplicate = FactoryBot.build(:bid, shipping_request: @shipping_request, traveler: @traveler)
    assert_not duplicate.valid?
  end

  test "should not allow bidding on non-biddable request" do
    @shipping_request.update!(status: "completed")
    new_bid = FactoryBot.build(:bid, shipping_request: @shipping_request, traveler: FactoryBot.create(:marketplace_user))
    assert_not new_bid.valid?
  end

  test "available_kg must cover request weight" do
    @bid.available_kg = 2 # less than shipping_request weight_kg of 5
    assert_not @bid.valid?
  end

  test "total_price_cents should calculate correctly" do
    @bid.price_per_kg_cents = 500
    assert_equal 2500, @bid.total_price_cents # 500 * 5kg
  end
end

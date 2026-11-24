require 'test_helper'

class BidTest < ActiveSupport::TestCase
  test "crée une offre valide en euros et calcule le total" do
    req = create_shipping_request(weight_kg: 4.5)
    traveler = create_user
    bid = Bid.create!(
      shipping_request: req,
      traveler: traveler,
      price_per_kg_euros: "12.50",
      available_kg: 10,
      currency: "EUR",
      travel_date: 8.days.from_now.to_date,
      flight_number: "AF718"
    )
    assert_equal 1250, bid.price_per_kg_cents
    assert_equal 12.5, bid.price_per_kg
    assert_equal 5625, bid.total_price_cents
    assert_equal 56.25, bid.total_price
  end

  test "interdit de faire une offre sur sa propre demande" do
    sender = create_user
    req = create_shipping_request(sender: sender)
    bid = Bid.new(
      shipping_request: req,
      traveler: sender,
      price_per_kg_cents: 1000,
      available_kg: 10,
      currency: "EUR",
      travel_date: 8.days.from_now.to_date
    )
    assert_not bid.valid?
    assert bid.errors[:base].any?
  end

  test "exige une capacité suffisante pour le poids du colis" do
    req = create_shipping_request(weight_kg: 8.0)
    bid = Bid.new(
      shipping_request: req,
      traveler: create_user,
      price_per_kg_cents: 1000,
      available_kg: 5.0,
      currency: "EUR",
      travel_date: 8.days.from_now.to_date
    )
    assert_not bid.valid?
    assert bid.errors[:available_kg].any?
  end

  test "withdraw! autorisé uniquement sur une offre pending" do
    req = create_shipping_request
    bid = create_bid(shipping_request: req)
    assert bid.withdrawable?
    bid.withdraw!
    assert_equal "withdrawn", bid.reload.status
    assert_not bid.withdrawable?

    req2 = create_shipping_request
    accepted_bid = create_bid(shipping_request: req2)
    req2.accept_bid!(accepted_bid)
    assert_raises(Bid::InvalidTransitionError) { accepted_bid.reload.withdraw! }
  end
end

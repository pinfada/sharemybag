require 'test_helper'

class ReviewTest < ActiveSupport::TestCase
  setup do
    @sender = create_user
    @traveler = create_user
    @outsider = create_user
    @request = create_shipping_request(sender: @sender)
    @bid = create_bid(shipping_request: @request, traveler: @traveler)
    @tracking = @request.accept_bid!(@bid)
  end

  test "refuse un avis tant que la livraison n'est pas confirmée" do
    review = Review.new(
      shipping_request: @request,
      reviewer: @sender,
      reviewee: @traveler,
      rating: 5,
      role: "sender"
    )
    assert_not review.valid?
  end

  test "autorise un avis par participant une fois la livraison confirmée et bloque les tiers" do
    @tracking.verify_and_hand_over!(@tracking.handover_code)
    @tracking.mark_in_transit!
    @tracking.verify_and_deliver!(@tracking.delivery_code)
    @tracking.confirm!

    outsider_review = Review.new(
      shipping_request: @request,
      reviewer: @outsider,
      reviewee: @traveler,
      rating: 1,
      role: "sender"
    )
    assert_not outsider_review.valid?

    wrong_target = Review.new(
      shipping_request: @request,
      reviewer: @sender,
      reviewee: @outsider,
      rating: 5,
      role: "sender"
    )
    assert_not wrong_target.valid?

    valid_review = Review.create!(
      shipping_request: @request,
      reviewer: @sender,
      reviewee: @traveler,
      rating: 5,
      comment: "Parfait du début à la fin.",
      role: "sender"
    )
    assert valid_review.persisted?

    duplicate = Review.new(
      shipping_request: @request,
      reviewer: @sender,
      reviewee: @traveler,
      rating: 4,
      role: "sender"
    )
    assert_not duplicate.valid?
  end
end

require 'test_helper'

class ShipmentTrackingTest < ActiveSupport::TestCase
  setup do
    @sender = create_user
    @traveler = create_user
    @request = create_shipping_request(sender: @sender)
    @bid = create_bid(shipping_request: @request, traveler: @traveler)
    @tracking = @request.accept_bid!(@bid)
  end

  test "génère deux codes cryptographiques distincts de 8 caractères" do
    assert_equal 8, @tracking.handover_code.length
    assert_equal 8, @tracking.delivery_code.length
    assert_not_equal @tracking.handover_code, @tracking.delivery_code
  end

  test "applique la machine à états complète dans l'ordre strict" do
    assert_not @tracking.verify_and_hand_over!("FAUXCODE")
    assert_equal "created", @tracking.reload.status

    assert @tracking.verify_and_hand_over!(" #{@tracking.handover_code.downcase} ")
    assert_equal "handed_over", @tracking.reload.status
    assert_not_nil @tracking.handed_over_at
    assert_equal "in_progress", @request.reload.status

    @tracking.mark_in_transit!
    assert_equal "in_transit", @tracking.reload.status
    assert_not_nil @tracking.in_transit_at

    assert_not @tracking.verify_and_deliver!("MAUVAIS1")
    assert @tracking.verify_and_deliver!(@tracking.delivery_code)
    assert_equal "delivered", @tracking.reload.status
    assert_not_nil @tracking.delivered_at

    @tracking.confirm!
    assert_equal "confirmed", @tracking.reload.status
    assert_not_nil @tracking.confirmed_at
    assert_equal "completed", @request.reload.status
  end

  test "empêche de sauter une étape de la machine à états" do
    assert_raises(ShipmentTracking::InvalidTransitionError) { @tracking.mark_in_transit! }
    assert_raises(ShipmentTracking::InvalidTransitionError) { @tracking.verify_and_deliver!(@tracking.delivery_code) }
    assert_raises(ShipmentTracking::InvalidTransitionError) { @tracking.confirm! }
  end

  test "exige la confirmation d'inspection ouverte avant d'accepter la remise du colis" do
    assert_not @tracking.verify_and_hand_over!(@tracking.handover_code, open_inspection_confirmed: false)
    assert_equal "created", @tracking.reload.status
    assert_nil @tracking.open_inspection_confirmed_at

    assert @tracking.verify_and_hand_over!(@tracking.handover_code, open_inspection_confirmed: true)
    assert_equal "handed_over", @tracking.reload.status
    assert_not_nil @tracking.open_inspection_confirmed_at
  end

  test "retourne une chronologie propre en 5 étapes" do
    timeline = @tracking.status_timeline
    assert_equal %w[created handed_over in_transit delivered confirmed], timeline.map { |s| s[:status] }
    assert timeline.first[:reached]
    assert_not timeline.second[:reached]
  end
end

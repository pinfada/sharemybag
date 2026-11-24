require 'test_helper'

class MarketplaceAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @sender = create_user(name: "Expéditeur Test")
    @traveler = create_user(name: "Voyageur Test")
    @outsider = create_user(name: "Tiers Test")
    @shipping_request = create_shipping_request(sender: @sender)
  end

  test "un visiteur non connecté peut parcourir et consulter les demandes ouvertes" do
    get shipping_requests_path
    assert_response :success
    assert_includes response.body, @shipping_request.title

    get shipping_request_path(@shipping_request)
    assert_response :success
    assert_includes response.body, @shipping_request.departure_city
  end

  test "seul l'expéditeur peut modifier, annuler ou accepter une offre sur sa demande" do
    bid = create_bid(shipping_request: @shipping_request, traveler: @traveler)

    sign_in_as(@outsider)
    get edit_shipping_request_path(@shipping_request)
    assert_redirected_to root_url

    patch shipping_request_path(@shipping_request), params: { shipping_request: { title: "Modifié" } }
    assert_redirected_to root_url
    assert_not_equal "Modifié", @shipping_request.reload.title

    post accept_bid_shipping_request_path(@shipping_request, bid_id: bid.id)
    assert_redirected_to root_url
    assert_equal "open", @shipping_request.reload.status

    delete shipping_request_path(@shipping_request)
    assert_redirected_to root_url
    assert_equal "open", @shipping_request.reload.status
  end

  test "impossible de modifier ou annuler une demande après acceptation d'une offre" do
    bid = create_bid(shipping_request: @shipping_request, traveler: @traveler)
    @shipping_request.accept_bid!(bid)

    sign_in_as(@sender)
    patch shipping_request_path(@shipping_request), params: { shipping_request: { title: "Tardif" } }
    assert_redirected_to shipping_request_path(@shipping_request)
    assert_not_equal "Tardif", @shipping_request.reload.title

    delete shipping_request_path(@shipping_request)
    assert_redirected_to shipping_request_path(@shipping_request)
    assert_equal "accepted", @shipping_request.reload.status
  end

  test "les codes de remise et de livraison ne sont JAMAIS exposés au voyageur" do
    bid = create_bid(shipping_request: @shipping_request, traveler: @traveler)
    tracking = @shipping_request.accept_bid!(bid)

    # Tiers refusé
    sign_in_as(@outsider)
    get shipment_tracking_path(tracking)
    assert_redirected_to root_url

    # Expéditeur VOIT le code de remise
    sign_in_as(@sender)
    get shipment_tracking_path(tracking)
    assert_response :success
    assert_includes response.body, tracking.handover_code
    assert_not_includes response.body, tracking.delivery_code

    # Voyageur NE VOIT PAS le code de remise
    sign_in_as(@traveler)
    get shipment_tracking_path(tracking)
    assert_response :success
    assert_not_includes response.body, tracking.handover_code
    assert_not_includes response.body, tracking.delivery_code

    # Passage en transit
    tracking.verify_and_hand_over!(tracking.handover_code)
    tracking.mark_in_transit!

    # Expéditeur VOIT le code de livraison
    sign_in_as(@sender)
    get shipment_tracking_path(tracking)
    assert_response :success
    assert_includes response.body, tracking.delivery_code

    # Voyageur NE VOIT PAS le code de livraison
    sign_in_as(@traveler)
    get shipment_tracking_path(tracking)
    assert_response :success
    assert_not_includes response.body, tracking.delivery_code
  end

  test "ReviewsController déduit reviewee et role côté serveur (anti-IDOR)" do
    bid = create_bid(shipping_request: @shipping_request, traveler: @traveler)
    tracking = @shipping_request.accept_bid!(bid)
    tracking.verify_and_hand_over!(tracking.handover_code)
    tracking.mark_in_transit!
    tracking.verify_and_deliver!(tracking.delivery_code)
    tracking.confirm!

    # Un tiers ne peut pas poster d'avis
    sign_in_as(@outsider)
    assert_no_difference "Review.count" do
      post shipping_request_reviews_path(@shipping_request), params: {
        review: { rating: 1, comment: "Spam", reviewee_id: @traveler.id, role: "sender" }
      }
    end

    # L'expéditeur tente de falsifier reviewee_id et role : le serveur force @traveler et "sender"
    sign_in_as(@sender)
    assert_difference "Review.count", 1 do
      post shipping_request_reviews_path(@shipping_request), params: {
        review: { rating: 5, comment: "Excellent", reviewee_id: @outsider.id, role: "traveler" }
      }
    end
    review = Review.last
    assert_equal @sender.id, review.reviewer_id
    assert_equal @traveler.id, review.reviewee_id
    assert_equal "sender", review.role
  end

  test "un tiers ne peut ni lire ni écrire dans une conversation privée" do
    conv = Conversation.create!(sender: @sender, recipient: @traveler, shipping_request: @shipping_request)
    conv.messages.create!(sender: @sender, body: "Rendez-vous terminal 2E")

    sign_in_as(@outsider)
    get conversation_path(conv)
    assert_redirected_to root_url

    assert_no_difference "Message.count" do
      post conversation_messages_path(conv), params: { message: { body: "Intrusion" } }
    end
    assert_redirected_to root_url
  end
end

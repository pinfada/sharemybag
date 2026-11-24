require 'test_helper'

class PagesAndActivityTest < ActionDispatch::IntegrationTest
  test "les pages publiques How it works, Privacy et Accessibility répondent avec succès" do
    get how_it_works_path
    assert_response :success
    assert_includes response.body, "reverse auction"

    get privacy_path
    assert_response :success
    assert_includes response.body, "Privacy"

    get accessibility_path
    assert_response :success
    assert_includes response.body, "RGAA"
  end

  test "mes demandes, mes propositions et notifications fonctionnent de bout en bout" do
    sender = create_user(name: "Nadia Expéditrice")
    traveler = create_user(name: "Youssef Voyageur")
    req = create_shipping_request(sender: sender, title: "Colis livres Lyon → Tunis")

    sign_in_as(traveler)
    post shipping_request_bids_path(req), params: {
      bid: {
        price_per_kg_euros: "9.50",
        available_kg: 6,
        travel_date: 10.days.from_now.to_date,
        flight_number: "TU721"
      }
    }
    bid = Bid.last

    get my_bids_bids_path
    assert_response :success
    assert_includes response.body, "Colis livres Lyon → Tunis"

    # Retrait autorisé tant que l'offre est pending
    patch withdraw_shipping_request_bid_path(req, bid)
    assert_redirected_to shipping_request_path(req)
    assert_equal "withdrawn", bid.reload.status

    sign_in_as(sender)
    get my_requests_shipping_requests_path
    assert_response :success
    assert_includes response.body, "Colis livres Lyon → Tunis"

    get notifications_path
    assert_response :success
    notif = sender.notifications.unread.first
    assert_not_nil notif

    patch mark_as_read_notification_path(notif)
    assert_redirected_to shipping_request_path(req)
    assert notif.reload.read?

    Notification.notify(sender, req, "new_bid", "Autre alerte")
    patch mark_all_as_read_notifications_path
    assert_redirected_to notifications_path
    assert_equal 0, sender.notifications.unread.count
  end

  test "séparation stricte des actions de suivi selon le rôle et rejet des mauvais codes" do
    sender = create_user
    traveler = create_user
    req = create_shipping_request(sender: sender)
    bid = create_bid(shipping_request: req, traveler: traveler)
    tracking = req.accept_bid!(bid)

    # L'expéditeur ne peut pas valider la remise à la place du voyageur
    sign_in_as(sender)
    post hand_over_shipment_tracking_path(tracking), params: { code: tracking.handover_code }
    assert_redirected_to root_url
    assert_equal "created", tracking.reload.status

    # Mauvais code soumis par le voyageur -> reste en created
    sign_in_as(traveler)
    post hand_over_shipment_tracking_path(tracking), params: { code: "WRONGCOD" }
    assert_redirected_to shipment_tracking_path(tracking)
    assert_equal "created", tracking.reload.status

    # Le voyageur ne peut pas confirmer la réception finale
    tracking.verify_and_hand_over!(tracking.handover_code)
    tracking.mark_in_transit!
    tracking.verify_and_deliver!(tracking.delivery_code)

    post confirm_shipment_tracking_path(tracking)
    assert_redirected_to root_url
    assert_equal "delivered", tracking.reload.status
  end

  test "une ressource inexistante redirige proprement sans erreur serveur" do
    get shipping_request_path(999_999)
    assert_redirected_to root_url
  end
end

require 'test_helper'

class EndToEndReverseAuctionTest < ActionDispatch::IntegrationTest
  test "parcours complet : publication, enchères, acceptation, messagerie, suivi par codes et avis mutuels" do
    # 1. Page d'accueil accessible avec proposition de valeur claire
    get root_path
    assert_response :success
    assert_includes response.body, "ShareMyBag"

    # 2. L'expéditeur s'inscrit et publie une demande d'envoi (budget en euros + attestation obligatoire)
    post users_path, params: {
      user: {
        name: "Sophie Expéditrice",
        email: "sophie@example.com",
        password: "Password123",
        password_confirmation: "Password123",
        city: "Paris",
        country: "France"
      }
    }
    sender = User.find_by!(email: "sophie@example.com")

    assert_difference "ShippingRequest.count", 1 do
      post shipping_requests_path, params: {
        shipping_request: {
          title: "Livres scolaires pour Dakar",
          description: "Carton compact de 4 kg de manuels scolaires.",
          weight_kg: 4.0,
          departure_city: "Paris",
          departure_country: "France",
          arrival_city: "Dakar",
          arrival_country: "Sénégal",
          desired_date: 12.days.from_now.to_date,
          max_budget_euros: "60",
          currency: "EUR",
          item_category: "documents",
          prohibited_items_acknowledged: "1"
        }
      }
    end
    req = ShippingRequest.last
    assert_equal 6000, req.max_budget_cents
    assert_redirected_to shipping_request_path(req)

    # 3. Deux voyageurs soumettent des offres concurrentes en €/kg
    traveler1 = create_user(name: "Karim Voyageur")
    traveler2 = create_user(name: "Lucie Voyageuse")

    sign_in_as(traveler1)
    get shipping_requests_path, params: { departure_city: "Paris", arrival_city: "Dakar" }
    assert_response :success
    assert_includes response.body, "Livres scolaires pour Dakar"

    assert_difference "Bid.count", 1 do
      post shipping_request_bids_path(req), params: {
        bid: {
          price_per_kg_euros: "10.00",
          available_kg: 8,
          travel_date: 12.days.from_now.to_date,
          flight_number: "AF718",
          message: "Je pars de CDG le matin, disponible pour remise la veille."
        }
      }
    end
    bid1 = Bid.last
    assert_equal 1000, bid1.price_per_kg_cents
    assert_equal 4000, bid1.total_price_cents
    assert_equal "bidding", req.reload.status

    sign_in_as(traveler2)
    post shipping_request_bids_path(req), params: {
      bid: {
        price_per_kg_euros: "13.00",
        available_kg: 6,
        travel_date: 13.days.from_now.to_date,
        flight_number: "HC404",
        message: "Vol Air Sénégal."
      }
    }
    bid2 = Bid.last

    # 4. L'expéditeur consulte les offres (prix exact en €, pas divisé deux fois) et accepte bid1
    sign_in_as(sender)
    get shipping_request_path(req)
    assert_response :success
    assert_includes response.body, "€10.00"
    assert_includes response.body, "€40.00"

    post accept_bid_shipping_request_path(req, bid_id: bid1.id)
    tracking = req.reload.shipment_tracking
    assert_not_nil tracking
    assert_redirected_to shipment_tracking_path(tracking)
    assert_equal "accepted", req.status
    assert_equal "accepted", bid1.reload.status
    assert_equal "rejected", bid2.reload.status

    # 5. Messagerie entre expéditeur et voyageur
    post conversations_path, params: { recipient_id: traveler1.id, shipping_request_id: req.id }
    conv = Conversation.between(sender, traveler1)
    assert_redirected_to conversation_path(conv)

    post conversation_messages_path(conv), params: { message: { body: "On se retrouve à 18h gare de Lyon ?" } }
    assert_equal 1, conv.messages.count

    # 6. Remise refusée sans confirmation d'inspection ouverte, puis acceptée avec case cochée + code
    sign_in_as(traveler1)
    post hand_over_shipment_tracking_path(tracking), params: { code: tracking.handover_code }
    assert_equal "created", tracking.reload.status

    post hand_over_shipment_tracking_path(tracking), params: { code: tracking.handover_code, open_inspection_confirmed: "1" }
    assert_redirected_to shipment_tracking_path(tracking)
    assert_equal "handed_over", tracking.reload.status
    assert_not_nil tracking.open_inspection_confirmed_at
    assert_equal "in_progress", req.reload.status

    # 7. Passage en transit puis livraison avec code de livraison
    post mark_in_transit_shipment_tracking_path(tracking)
    assert_equal "in_transit", tracking.reload.status

    post deliver_shipment_tracking_path(tracking), params: { code: tracking.delivery_code }
    assert_equal "delivered", tracking.reload.status

    # 8. Confirmation finale par l'expéditeur
    sign_in_as(sender)
    post confirm_shipment_tracking_path(tracking)
    assert_equal "confirmed", tracking.reload.status
    assert_equal "completed", req.reload.status

    # 9. Avis mutuels
    post shipping_request_reviews_path(req), params: {
      review: { rating: 5, comment: "Colis arrivé intact et à l'heure !" }
    }
    sign_in_as(traveler1)
    post shipping_request_reviews_path(req), params: {
      review: { rating: 5, comment: "Expéditrice ponctuelle et colis bien emballé." }
    }

    assert_equal 5.0, traveler1.reload.average_rating
    assert_equal 5.0, sender.reload.average_rating
    assert_equal 1, traveler1.completed_shipments_count
  end
end

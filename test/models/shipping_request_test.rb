require 'test_helper'

class ShippingRequestTest < ActiveSupport::TestCase
  test "crée une demande valide avec attestation d'objets autorisés" do
    req = create_shipping_request
    assert req.persisted?
    assert_equal "open", req.status
    assert req.open_for_bids?
    assert req.editable?
    assert req.cancellable?
  end

  test "exige l'attestation d'absence d'objets interdits à la création" do
    sender = create_user
    req = ShippingRequest.new(
      sender: sender,
      title: "Colis test",
      weight_kg: 2,
      departure_city: "Paris",
      departure_country: "France",
      arrival_city: "Lyon",
      arrival_country: "France",
      desired_date: 5.days.from_now.to_date,
      currency: "EUR",
      prohibited_items_acknowledged: false
    )
    assert_not req.valid?
    assert req.errors[:prohibited_items_acknowledged].any?
  end

  test "convertit max_budget_euros en centimes proprement" do
    sender = create_user
    req = create_shipping_request(sender: sender, max_budget_euros: "75.50", max_budget_cents: nil)
    assert_equal 7550, req.max_budget_cents
    assert_equal 75.5, req.max_budget_euros
  end

  test "rejette un poids hors bornes et une date passée" do
    req = ShippingRequest.new(
      sender: create_user,
      title: "Trop lourd",
      weight_kg: 60,
      departure_city: "Paris",
      departure_country: "France",
      arrival_city: "Dakar",
      arrival_country: "Sénégal",
      desired_date: Date.yesterday,
      currency: "EUR",
      prohibited_items_acknowledged: true
    )
    assert_not req.valid?
    assert req.errors[:weight_kg].any?
    assert req.errors[:desired_date].any?
  end

  test "rejette une deadline antérieure à la date souhaitée" do
    req = ShippingRequest.new(
      sender: create_user,
      title: "Dates incohérentes",
      weight_kg: 5,
      departure_city: "Paris",
      departure_country: "France",
      arrival_city: "Dakar",
      arrival_country: "Sénégal",
      desired_date: 10.days.from_now.to_date,
      deadline_date: 5.days.from_now.to_date,
      currency: "EUR",
      prohibited_items_acknowledged: true
    )
    assert_not req.valid?
    assert req.errors[:deadline_date].any?
  end

  test "accept_bid! accepte atomiquement l'offre, rejette les autres pending et crée le suivi" do
    sender = create_user
    t1 = create_user
    t2 = create_user
    t3 = create_user
    req = create_shipping_request(sender: sender)
    bid1 = create_bid(shipping_request: req, traveler: t1, price_per_kg_cents: 1000)
    bid2 = create_bid(shipping_request: req, traveler: t2, price_per_kg_cents: 1200)
    bid3 = create_bid(shipping_request: req, traveler: t3, price_per_kg_cents: 1500)
    bid3.withdraw!

    tracking = req.accept_bid!(bid1)

    assert_equal "accepted", req.reload.status
    assert_equal "accepted", bid1.reload.status
    assert_equal "rejected", bid2.reload.status
    assert_equal "withdrawn", bid3.reload.status
    assert_not_nil tracking
    assert_equal t1.id, tracking.traveler_id
    assert_equal "created", tracking.status
    assert_not req.editable?
    assert_not req.cancellable?
  end

  test "accept_bid! refuse une double acceptation ou une offre retirée" do
    req = create_shipping_request
    bid1 = create_bid(shipping_request: req)
    bid2 = create_bid(shipping_request: req)
    bid2.withdraw!

    assert_raises(ShippingRequest::InvalidActionError) { req.accept_bid!(bid2) }

    req.accept_bid!(bid1)
    assert_raises(ShippingRequest::InvalidActionError) { req.accept_bid!(bid1) }
  end

  test "les scopes de recherche échappent les jokers SQL LIKE" do
    create_shipping_request(departure_city: "Paris", arrival_city: "Dakar")
    create_shipping_request(departure_city: "Lyon", arrival_city: "Tunis")

    assert_equal 0, ShippingRequest.search_departure("%").count
    assert_equal 1, ShippingRequest.search_departure("par").count
    assert_equal 1, ShippingRequest.search_arrival("dak").count
  end

  test "détecte les trajets internationaux et le dépassement du seuil de franchise douanière (430 €)" do
    domestic = create_shipping_request(departure_country: "France", arrival_country: "france", declared_value_euros: "600")
    assert_not domestic.international?
    assert_not domestic.above_customs_allowance?

    intl_low = create_shipping_request(departure_country: "France", arrival_country: "Senegal", declared_value_euros: "120.50")
    assert intl_low.international?
    assert_equal 12_050, intl_low.declared_value_cents
    assert_equal 120.5, intl_low.declared_value_euros
    assert_not intl_low.above_customs_allowance?

    intl_high = create_shipping_request(departure_country: "France", arrival_country: "Canada", declared_value_euros: "500")
    assert intl_high.international?
    assert intl_high.above_customs_allowance?
  end
end

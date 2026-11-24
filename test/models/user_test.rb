require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "crée un utilisateur valide avec mot de passe robuste" do
    user = create_user(name: "Aminata Diallo", email: "Aminata@Example.COM")
    assert user.persisted?
    assert_equal "aminata@example.com", user.email
    assert_not_nil user.remember_token
  end

  test "rejette un mot de passe faible" do
    user = User.new(
      name: "Test",
      email: "weak@example.com",
      password: "password",
      password_confirmation: "password"
    )
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "rejette un email en doublon insensible à la casse" do
    create_user(email: "marie@example.com")
    duplicate = User.new(
      name: "Autre Marie",
      email: "MARIE@example.com",
      password: "Password123",
      password_confirmation: "Password123"
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?
  end

  test "permet la mise à jour du profil sans ressaisir le mot de passe" do
    user = create_user
    assert user.update(name: "Nouveau Nom", city: "Lyon", bio: "Voyageur régulier")
    assert_equal "Nouveau Nom", user.reload.name
    assert_equal "Lyon", user.city
  end

  test "User.digest retourne nil pour une valeur vide ou nil" do
    assert_nil User.digest(nil)
    assert_nil User.digest("")
    assert_equal 64, User.digest("secret-token").length
  end

  test "calcule les initiales et la note moyenne correctement" do
    sender = create_user(name: "Marie Laurent")
    traveler = create_user(name: "Ousmane Ba")
    assert_equal "ML", sender.initials
    assert_equal 0.0, traveler.average_rating
    assert_equal 0, traveler.completed_shipments_count

    req = create_shipping_request(sender: sender)
    bid = create_bid(shipping_request: req, traveler: traveler)
    tracking = req.accept_bid!(bid)
    tracking.verify_and_hand_over!(tracking.handover_code)
    tracking.mark_in_transit!
    tracking.verify_and_deliver!(tracking.delivery_code)
    tracking.confirm!

    Review.create!(
      shipping_request: req,
      reviewer: sender,
      reviewee: traveler,
      rating: 5,
      comment: "Remise ponctuelle et sérieuse.",
      role: "sender"
    )

    assert_equal 5.0, traveler.average_rating
    assert_equal 1, traveler.completed_shipments_count
    assert_equal 1, sender.completed_shipments_count
  end
end

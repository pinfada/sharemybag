ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Helpers de création de données de test (zéro dépendance externe)
  def create_user(attrs = {})
    seq = next_seq
    defaults = {
      name: "Utilisateur #{seq}",
      email: "user#{seq}@example.com",
      password: "Password123",
      password_confirmation: "Password123",
      city: "Paris",
      country: "France",
      currency: "EUR"
    }
    User.create!(defaults.merge(attrs))
  end

  def create_shipping_request(sender: nil, **attrs)
    sender ||= create_user
    defaults = {
      sender: sender,
      title: "Documents professionnels",
      description: "Enveloppe sécurisée contenant des documents administratifs.",
      weight_kg: 3.0,
      departure_city: "Paris",
      departure_country: "France",
      arrival_city: "Dakar",
      arrival_country: "Sénégal",
      desired_date: 10.days.from_now.to_date,
      max_budget_cents: 6000,
      currency: "EUR",
      item_category: "documents",
      prohibited_items_acknowledged: true
    }
    ShippingRequest.create!(defaults.merge(attrs))
  end

  def create_bid(shipping_request: nil, traveler: nil, **attrs)
    shipping_request ||= create_shipping_request
    traveler ||= create_user
    defaults = {
      shipping_request: shipping_request,
      traveler: traveler,
      price_per_kg_cents: 1200,
      available_kg: 10.0,
      currency: shipping_request.currency,
      travel_date: shipping_request.desired_date,
      flight_number: "AF718",
      message: "Vol direct, remise possible à l'aéroport ou en centre-ville."
    }
    Bid.create!(defaults.merge(attrs))
  end

  private

  def next_seq
    @test_seq = (@test_seq || 0) + 1
    "#{Process.pid}_#{Time.now.to_f.to_s.delete('.')}_#{@test_seq}"
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user, password: "Password123")
    post sessions_path, params: {
      session: { email: user.email, password: password }
    }
    follow_redirect! if response.redirect?
  end
end

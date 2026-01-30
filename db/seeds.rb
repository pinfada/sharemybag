# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with: rails db:seed
#
# ShareMyBag - Marketplace de transport de bagages
# ================================================

require 'faker'
require 'open-uri'
require 'nokogiri'

puts "🧹 Nettoyage de la base de données..."

# Suppression dans l'ordre des dépendances
Review.destroy_all
ShipmentTracking.destroy_all
Transaction.destroy_all
Bid.destroy_all
ShippingRequest.destroy_all
KiloOffer.destroy_all
Message.destroy_all
Conversation.destroy_all
Notification.destroy_all
IdentityVerification.destroy_all
Bagage.destroy_all
Paquet.destroy_all
Booking.destroy_all
Micropost.destroy_all
Relationship.destroy_all
User.destroy_all  # Supprimer les Users avant les Vols car les Users référencent les Vols
Vol.destroy_all
Coordonnee.destroy_all
Airport.destroy_all

# Reset des séquences d'ID
ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.reset_pk_sequence!(table)
end

puts "✅ Base de données nettoyée"
puts "\n📦 Création des données de test...\n"

# ================================================
# AÉROPORTS (Créés en premier car nécessaires pour les vols)
# ================================================
puts "✈️ Création des aéroports..."

def create_airports
  # Aéroports majeurs français et internationaux
  major_airports = [
    { code: "CDG", location: "Paris Charles de Gaulle", country: "France" },
    { code: "ORY", location: "Paris Orly", country: "France" },
    { code: "NCE", location: "Nice Côte d'Azur", country: "France" },
    { code: "LYS", location: "Lyon Saint-Exupéry", country: "France" },
    { code: "MRS", location: "Marseille Provence", country: "France" },
    { code: "TLS", location: "Toulouse Blagnac", country: "France" },
    { code: "BOD", location: "Bordeaux Mérignac", country: "France" },
    { code: "NTE", location: "Nantes Atlantique", country: "France" },
    { code: "LHR", location: "London Heathrow", country: "UK" },
    { code: "JFK", location: "New York JFK", country: "USA" },
    { code: "LAX", location: "Los Angeles", country: "USA" },
    { code: "DXB", location: "Dubai International", country: "UAE" },
    { code: "HND", location: "Tokyo Haneda", country: "Japan" },
    { code: "SIN", location: "Singapore Changi", country: "Singapore" },
    { code: "BCN", location: "Barcelona El Prat", country: "Spain" },
    { code: "AMS", location: "Amsterdam Schiphol", country: "Netherlands" },
    { code: "FRA", location: "Frankfurt", country: "Germany" },
    { code: "IST", location: "Istanbul", country: "Turkey" },
    { code: "BKK", location: "Bangkok Suvarnabhumi", country: "Thailand" },
    { code: "SYD", location: "Sydney Kingsford Smith", country: "Australia" }
  ]

  major_airports.each do |airport_data|
    airport = Airport.create!(
      code: airport_data[:code],
      location: "#{airport_data[:location]}, #{airport_data[:country]}"
    )

    Coordonnee.create!(
      titre: airport_data[:location],
      description: "Aéroport international - Hub de transport majeur",
      airport_id: airport.id
    )
  end
end

create_airports
puts "✅ #{Airport.count} aéroports créés"

# ================================================
# VOLS
# ================================================
puts "✈️ Création des vols..."

def create_flights
  airlines = ["Air France", "Lufthansa", "British Airways", "Emirates", "Delta", "United", "Qatar Airways", "Singapore Airlines", "KLM", "Ryanair", "EasyJet"]
  airports = Airport.all.to_a

  # Créer 200 vols sur les 90 prochains jours
  200.times do
    departure_airport = airports.sample
    arrival_airport = (airports - [departure_airport]).sample

    departure_date = rand(1..90).days.from_now + rand(0..23).hours + rand(0..59).minutes
    flight_duration = rand(60..720).minutes # Entre 1h et 12h

    Vol.create!(
      num_vol: "#{airlines.sample.split.map(&:first).join} #{rand(100..999)}",
      date_depart: departure_date,
      duree: flight_duration,
      provenance_id: departure_airport.id,
      destination_id: arrival_airport.id
    )
  end
end

create_flights
puts "✅ #{Vol.count} vols créés"

# ================================================
# UTILISATEURS (Créés après les vols car peuvent avoir une référence vol_id)
# ================================================
puts "👥 Création des utilisateurs..."

# Récupérer quelques vols pour associer optionnellement aux utilisateurs
sample_vols = Vol.limit(10).to_a

# Admin user
admin = User.create!(
  name: "Admin ShareMyBag",
  email: "admin@sharemybag.com",
  password: "Admin123!",
  password_confirmation: "Admin123!",
  admin: true,
  email_verified: true,
  city: "Paris",
  country: "France",
  currency: "EUR"
)

# Test users
demo_user = User.create!(
  name: "Demo User",
  email: "demo@sharemybag.com",
  password: "Demo123!",
  password_confirmation: "Demo123!",
  email_verified: true,
  city: "Lyon",
  country: "France",
  currency: "EUR"
)

traveler = User.create!(
  name: "Marie Voyageuse",
  email: "marie@example.com",
  password: "Marie123!",
  password_confirmation: "Marie123!",
  email_verified: true,
  city: "Nice",
  country: "France",
  currency: "EUR",
  bio: "Voyageuse fréquente, spécialisée dans le transport Europe-Asie",
  vol_id: sample_vols.sample&.id  # Associer un vol optionnellement
)

sender = User.create!(
  name: "Pierre Expéditeur",
  email: "pierre@example.com",
  password: "Pierre123!",
  password_confirmation: "Pierre123!",
  email_verified: true,
  city: "Marseille",
  country: "France",
  currency: "EUR",
  bio: "Entrepreneur e-commerce, envois réguliers vers l'international"
)

# Création de 20 utilisateurs supplémentaires
users = [admin, demo_user, traveler, sender]
20.times do |n|
  users << User.create!(
    name: Faker::Name.name,
    email: "user#{n+1}@example.com",
    password: "Password123!",
    password_confirmation: "Password123!",
    email_verified: true,
    city: Faker::Address.city,
    country: Faker::Address.country,
    currency: ["EUR", "USD", "GBP"].sample,
    bio: Faker::Lorem.sentence(word_count: 15),
    phone: Faker::PhoneNumber.phone_number,
    vol_id: rand(3) == 0 ? sample_vols.sample&.id : nil  # 1/3 des utilisateurs ont un vol associé
  )
end

puts "✅ #{User.count} utilisateurs créés"

# ================================================
# DEMANDES D'EXPÉDITION (SHIPPING REQUESTS)
# ================================================
puts "📦 Création des demandes d'expédition..."

cities = ["Paris", "Lyon", "Marseille", "Nice", "Toulouse", "Bordeaux", "Nantes", "Londres", "New York", "Tokyo", "Dubai", "Singapour"]

30.times do
  departure_city = cities.sample
  arrival_city = (cities - [departure_city]).sample

  ShippingRequest.create!(
    sender: users.sample,
    title: "Envoi #{Faker::Commerce.product_name}",
    description: Faker::Lorem.paragraph(sentence_count: 3),
    weight_kg: rand(0.5..20.0).round(1),
    length_cm: rand(10..60),
    width_cm: rand(10..50),
    height_cm: rand(5..40),
    departure_city: departure_city,
    departure_country: ["France", "UK", "USA", "Germany", "Spain"].sample,
    arrival_city: arrival_city,
    arrival_country: ["France", "UK", "USA", "Germany", "Spain"].sample,
    desired_date: rand(5..30).days.from_now,
    deadline_date: rand(31..60).days.from_now,
    max_budget_cents: rand(2000..20000),
    currency: "EUR",
    status: ["open", "bidding", "accepted", "in_progress", "completed", "cancelled"].sample,
    item_category: ["electronics", "clothing", "documents", "books", "cosmetics", "food", "gifts", "sports", "art"].sample,
    special_instructions: rand(3) == 0 ? Faker::Lorem.sentence : nil,
    prohibited_items_acknowledged: true,
    content_declaration_verified: true,
    declared_value_cents: rand(5000..50000),
    declared_contents: Faker::Commerce.product_name,
    contains_dangerous_goods: false,
    insurance_required: rand(2) == 0,
    insurance_value_cents: rand(2) == 0 ? rand(10000..100000) : nil,
    compliance_status: ["pending", "cleared", "rejected"].sample,
    airline_restrictions_checked: true
  )
end

puts "✅ #{ShippingRequest.count} demandes d'expédition créées"

# ================================================
# OFFRES DE KILOS
# ================================================
puts "🧳 Création des offres de kilos..."

30.times do
  vol = Vol.all.sample
  departure_airport = Airport.find(vol.provenance_id)
  arrival_airport = Airport.find(vol.destination_id)

  KiloOffer.create!(
    traveler: users.sample,  # Utiliser 'traveler' au lieu de 'user'
    vol_id: vol.id,  # Associer le vol
    departure_city: departure_airport.location.split(',').first,
    departure_country: departure_airport.location.split(',').last.strip,  # Ajouter le pays de départ
    arrival_city: arrival_airport.location.split(',').first,
    arrival_country: arrival_airport.location.split(',').last.strip,  # Ajouter le pays d'arrivée
    travel_date: vol.date_depart.to_date,  # Utiliser 'travel_date' au lieu de 'departure_date'
    available_kg: rand(5..30),  # Utiliser 'available_kg' au lieu de 'available_weight'
    price_per_kg_cents: rand(500..2500),  # Utiliser 'price_per_kg_cents' (en centimes)
    currency: "EUR",
    flight_number: vol.num_vol,
    accepted_items: Faker::Lorem.sentence(word_count: 10),  # Champ optionnel pour les éléments acceptés
    restrictions: Faker::Lorem.sentence(word_count: 8),  # Champ optionnel pour les restrictions
    status: ["active", "booked", "completed", "expired"].sample  # Statuts valides selon le modèle
  )
end

puts "✅ #{KiloOffer.count} offres de kilos créées"

# ================================================
# ENCHÈRES (BIDS)
# ================================================
puts "💰 Création des enchères..."

ShippingRequest.where(status: ["open", "bidding"]).each do |request|
  # Sélectionner des voyageurs uniques pour chaque demande (éviter les doublons)
  potential_travelers = users - [request.sender]
  selected_travelers = potential_travelers.sample(rand(2..5))

  # Décider si cette demande aura un bid accepté (seulement le premier)
  will_accept_bid = rand(2) == 0

  selected_travelers.each_with_index do |traveler, index|
    # Seulement le premier bid peut être accepté si will_accept_bid est true
    bid_status = if will_accept_bid && index == 0
                   "accepted"
                 else
                   ["pending", "rejected", "withdrawn"].sample
                 end

    Bid.create!(
      shipping_request: request,
      traveler: traveler,  # Utiliser 'traveler' au lieu de 'user'
      price_per_kg_cents: rand(500..2500),  # Prix par kg en centimes
      available_kg: rand(request.weight_kg..30),  # Capacité disponible >= poids demandé
      travel_date: rand(5..30).days.from_now,  # Date de voyage future
      currency: "EUR",
      flight_number: "AF#{rand(100..999)}",  # Numéro de vol optionnel
      message: Faker::Lorem.sentence(word_count: 20),
      status: bid_status
    )
  end
end

puts "✅ #{Bid.count} enchères créées"

# ================================================
# TRANSACTIONS
# ================================================
puts "💳 Création des transactions..."

# Créer une transaction uniquement pour les bids acceptés qui n'ont pas déjà de transaction
Bid.where(status: "accepted").each do |bid|
  # Vérifier qu'il n'y a pas déjà une transaction pour cette ShippingRequest
  next if Transaction.exists?(shipping_request_id: bid.shipping_request_id)

  Transaction.create!(
    sender_id: bid.shipping_request.sender_id,
    traveler_id: bid.traveler_id,  # Utiliser 'traveler_id' au lieu de 'carrier_id'
    shipping_request_id: bid.shipping_request_id,
    bid_id: bid.id,
    amount_cents: bid.total_price_cents,  # Utiliser amount_cents calculé depuis le bid
    platform_fee_cents: (bid.total_price_cents * 0.15).round,  # 15% de frais de plateforme
    traveler_payout_cents: (bid.total_price_cents * 0.85).round,  # 85% pour le voyageur
    currency: bid.currency,
    status: ["pending", "paid", "escrow", "released", "refunded", "disputed"].sample,  # Ajout de "escrow"
    payment_method: ["credit_card", "bank_transfer"].sample,  # Méthodes valides selon le schéma
    escrow_released_at: rand(2) == 0 ? rand(1..10).days.from_now : nil
  )
end

puts "✅ #{Transaction.count} transactions créées"

# ================================================
# SUIVIS D'EXPÉDITION
# ================================================
puts "📍 Création des suivis d'expédition..."

Transaction.where(status: ["paid", "escrow", "released"]).each do |transaction|
  # Ne pas définir handover_code et delivery_code, ils sont générés automatiquement
  ShipmentTracking.create!(
    shipping_request_id: transaction.shipping_request_id,
    traveler_id: transaction.traveler_id,  # Utiliser 'traveler_id' au lieu de 'carrier_id'
    status: ["created", "handed_over", "in_transit", "delivered", "confirmed"].sample,
    # Les codes sont générés automatiquement par le callback before_create
    handed_over_at: rand(2) == 0 ? rand(1..5).days.ago : nil,
    in_transit_at: rand(2) == 0 ? rand(1..3).days.ago : nil,
    delivered_at: rand(2) == 0 ? rand(1..2).days.ago : nil,
    confirmed_at: rand(2) == 0 ? Time.current : nil
  )
end

puts "✅ #{ShipmentTracking.count} suivis créés"

# ================================================
# VÉRIFICATIONS D'IDENTITÉ
# ================================================
puts "🆔 Création des vérifications d'identité..."

users.first(10).each do |user|
  IdentityVerification.create!(
    user: user,
    document_type: ["passport", "id_card", "driver_license"].sample,  # 'id_card' au lieu de 'national_id'
    status: ["pending", "verified", "rejected"].sample,
    verified_at: rand(2) == 0 ? rand(1..30).days.ago : nil,
    rejection_reason: nil,
    document_number_hash: "HASH#{rand(100000..999999)}",  # Hash du numéro de document
    document_country: ["France", "UK", "USA", "Germany"].sample,
    document_expiry_date: rand(1..5).years.from_now
  )
end

puts "✅ #{IdentityVerification.count} vérifications créées"

# ================================================
# AVIS (REVIEWS)
# ================================================
puts "⭐ Création des avis..."

Transaction.where(status: "released").each do |transaction|
  # Marquer la ShippingRequest comme complétée pour permettre les reviews
  transaction.shipping_request.update!(status: "completed")

  # Avis du sender sur le traveler
  Review.create!(
    reviewer_id: transaction.sender_id,
    reviewee_id: transaction.traveler_id,  # 'reviewee_id' au lieu de 'reviewed_id'
    shipping_request_id: transaction.shipping_request_id,  # Utiliser shipping_request_id
    rating: rand(3..5),
    comment: Faker::Lorem.paragraph(sentence_count: 3),
    role: "sender"  # 'role' au lieu de 'reviewer_type'
  )

  # Avis du traveler sur le sender
  if rand(3) > 0
    Review.create!(
      reviewer_id: transaction.traveler_id,
      reviewee_id: transaction.sender_id,
      shipping_request_id: transaction.shipping_request_id,
      rating: rand(3..5),
      comment: Faker::Lorem.paragraph(sentence_count: 2),
      role: "traveler"  # 'role' au lieu de 'reviewer_type'
    )
  end
end

puts "✅ #{Review.count} avis créés"

# ================================================
# CONVERSATIONS ET MESSAGES
# ================================================
puts "💬 Création des conversations et messages..."

15.times do
  user1 = users.sample
  user2 = (users - [user1]).sample

  conversation = Conversation.create!(
    sender_id: user1.id,
    recipient_id: user2.id  # 'recipient_id' au lieu de 'receiver_id'
  )

  # Créer 3 à 10 messages par conversation
  rand(3..10).times do
    Message.create!(
      conversation: conversation,
      sender_id: [user1, user2].sample.id,  # 'sender_id' au lieu de 'user'
      body: Faker::Lorem.sentence(word_count: rand(5..20)),
      read: [true, false].sample
    )
  end
end

puts "✅ #{Conversation.count} conversations et #{Message.count} messages créés"

# ================================================
# NOTIFICATIONS
# ================================================
puts "🔔 Création des notifications..."

users.each do |user|
  rand(0..5).times do
    # Créer une notification avec un objet notifiable aléatoire
    notifiable_types = ["ShippingRequest", "Bid", "Transaction", "Message"]
    notifiable_type = notifiable_types.sample

    notifiable = case notifiable_type
    when "ShippingRequest"
      ShippingRequest.all.sample || ShippingRequest.first
    when "Bid"
      Bid.all.sample || Bid.first
    when "Transaction"
      Transaction.all.sample || Transaction.first
    when "Message"
      Message.all.sample || Message.first
    end

    if notifiable
      Notification.create!(
        user: user,
        notifiable_type: notifiable_type,
        notifiable_id: notifiable.id,
        action: ["new_bid", "bid_accepted", "payment_received", "package_delivered", "new_message", "verification_approved"].sample,
        message: Faker::Lorem.sentence(word_count: 15),
        read: [true, false].sample
      )
    end
  end
end

puts "✅ #{Notification.count} notifications créées"

# ================================================
# MICROPOSTS (ACTIVITÉ SOCIALE)
# ================================================
puts "📝 Création des microposts..."

users.first(10).each do |user|
  rand(2..5).times do
    user.microposts.create!(
      content: Faker::Lorem.sentence(word_count: rand(5..15))[0..139]  # Limiter à 140 caractères
    )
  end
end

puts "✅ #{Micropost.count} microposts créés"

# ================================================
# RELATIONS (FOLLOWING/FOLLOWERS)
# ================================================
puts "👥 Création des relations de suivi..."

users.each do |user|
  following = users.sample(rand(2..5))
  following.each do |followed|
    user.follow!(followed) unless user == followed  # Utiliser follow! au lieu de follow
  end
end

puts "✅ #{Relationship.count} relations créées"

# ================================================
# RÉSUMÉ FINAL
# ================================================
puts "\n" + "="*50
puts "🎉 SEED TERMINÉ AVEC SUCCÈS!"
puts "="*50
puts "\n📊 Résumé des données créées:"
puts "  👥 Utilisateurs: #{User.count}"
puts "  ✈️ Aéroports: #{Airport.count}"
puts "  ✈️ Vols: #{Vol.count}"
puts "  📦 Demandes d'expédition: #{ShippingRequest.count}"
puts "  🧳 Offres de kilos: #{KiloOffer.count}"
puts "  💰 Enchères: #{Bid.count}"
puts "  💳 Transactions: #{Transaction.count}"
puts "  📍 Suivis: #{ShipmentTracking.count}"
puts "  🆔 Vérifications: #{IdentityVerification.count}"
puts "  ⭐ Avis: #{Review.count}"
puts "  💬 Conversations: #{Conversation.count}"
puts "  💬 Messages: #{Message.count}"
puts "  🔔 Notifications: #{Notification.count}"
puts "  📝 Microposts: #{Micropost.count}"
puts "  👥 Relations: #{Relationship.count}"

puts "\n🔐 Comptes de test:"
puts "  Admin: admin@sharemybag.com / Admin123!"
puts "  Demo: demo@sharemybag.com / Demo123!"
puts "  Marie: marie@example.com / Marie123!"
puts "  Pierre: pierre@example.com / Pierre123!"
puts "\n✅ Base de données prête à l'emploi!"
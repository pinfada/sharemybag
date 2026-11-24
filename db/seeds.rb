# Realistic English demo seed data for ShareMyBag (zero external dependencies)

puts "Cleaning database..."
Review.delete_all
Notification.delete_all
Message.delete_all
Conversation.delete_all
ShipmentTracking.delete_all
Bid.delete_all
ShippingRequest.delete_all
User.delete_all

ActiveRecord::Base.connection.tables.each do |table|
  next if %w[schema_migrations ar_internal_metadata].include?(table)
  ActiveRecord::Base.connection.reset_pk_sequence!(table)
end

puts "Creating demo members..."
marie = User.create!(
  name: "Marie Laurent",
  email: "marie@example.com",
  password: "Marie123!",
  password_confirmation: "Marie123!",
  city: "Paris",
  country: "France",
  bio: "Regular sender shipping books and personal items to West Africa and North America."
)

pierre = User.create!(
  name: "Pierre Bernard",
  email: "pierre@example.com",
  password: "Pierre123!",
  password_confirmation: "Pierre123!",
  city: "London",
  country: "United Kingdom",
  bio: "Frequent business traveler happy to share spare checked luggage allowance."
)

demo = User.create!(
  name: "Camille Moreau",
  email: "demo@sharemybag.com",
  password: "Demo123!",
  password_confirmation: "Demo123!",
  city: "Lyon",
  country: "France",
  bio: "Demo account for testing both sender and traveler workflows."
)

aminata = User.create!(
  name: "Aminata Diallo",
  email: "aminata@example.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  city: "Paris",
  country: "France",
  bio: "Monthly round trips between Paris and Dakar."
)

youssef = User.create!(
  name: "Youssef Benali",
  email: "youssef@example.com",
  password: "Password123!",
  password_confirmation: "Password123!",
  city: "Toulouse",
  country: "France",
  bio: "Engineering consultant flying regularly to Canada and North Africa."
)

puts "Creating shipping requests..."
req_dakar = ShippingRequest.create!(
  sender: marie,
  title: "High school textbooks and notebooks to Dakar",
  description: "Clean, compact 6 kg box of school textbooks. Ready for open visual inspection at handover.",
  weight_kg: 6.0,
  length_cm: 40, width_cm: 30, height_cm: 20,
  departure_city: "Paris", departure_country: "France",
  arrival_city: "Dakar", arrival_country: "Senegal",
  desired_date: 12.days.from_now.to_date,
  deadline_date: 20.days.from_now.to_date,
  max_budget_euros: 75,
  declared_value_euros: 140,
  item_category: "books",
  special_instructions: "Flexible handover at Paris Gare de Lyon or CDG Airport.",
  prohibited_items_acknowledged: true
)

req_montreal = ShippingRequest.create!(
  sender: demo,
  title: "Winter coats and knitwear",
  description: "Soft 8 kg duffle bag with personal winter coats and sweaters.",
  weight_kg: 8.0,
  departure_city: "Lyon", departure_country: "France",
  arrival_city: "Montreal", arrival_country: "Canada",
  desired_date: 16.days.from_now.to_date,
  deadline_date: 28.days.from_now.to_date,
  max_budget_euros: 100,
  declared_value_euros: 480,
  item_category: "clothing",
  prohibited_items_acknowledged: true
)

req_tunis = ShippingRequest.create!(
  sender: marie,
  title: "Urgent notarized paperwork folder",
  description: "Rigid A4 envelope weighing 1 kg containing original administrative documents.",
  weight_kg: 1.0,
  length_cm: 32, width_cm: 24, height_cm: 3,
  departure_city: "Marseille", departure_country: "France",
  arrival_city: "Tunis", arrival_country: "Tunisia",
  desired_date: 8.days.from_now.to_date,
  max_budget_euros: 25,
  item_category: "documents",
  prohibited_items_acknowledged: true
)

req_abidjan = ShippingRequest.create!(
  sender: aminata,
  title: "Computer peripherals in original boxes",
  description: "Wired mechanical keyboard, mouse (no lithium battery), and USB-C cables.",
  weight_kg: 3.5,
  departure_city: "London", departure_country: "United Kingdom",
  arrival_city: "Abidjan", arrival_country: "Ivory Coast",
  desired_date: 14.days.from_now.to_date,
  max_budget_euros: 55,
  item_category: "electronics",
  prohibited_items_acknowledged: true
)

req_casablanca = ShippingRequest.create!(
  sender: demo,
  title: "Newborn baby clothes gift box",
  description: "Organic cotton baby clothes and plush toy, 2.5 kg total.",
  weight_kg: 2.5,
  departure_city: "Bordeaux", departure_country: "France",
  arrival_city: "Casablanca", arrival_country: "Morocco",
  desired_date: 11.days.from_now.to_date,
  max_budget_euros: 40,
  item_category: "gifts",
  prohibited_items_acknowledged: true
)

# Active competing offers on Paris -> Dakar
Bid.create!(
  shipping_request: req_dakar,
  traveler: pierre,
  price_per_kg_euros: 10.50,
  available_kg: 12,
  travel_date: 12.days.from_now.to_date,
  flight_number: "AF718",
  message: "Direct Air France flight from CDG. Available the evening before in central Paris."
)
Bid.create!(
  shipping_request: req_dakar,
  traveler: aminata,
  price_per_kg_euros: 9.00,
  available_kg: 10,
  travel_date: 14.days.from_now.to_date,
  flight_number: "HC404",
  message: "Experienced carrying books; handover available in Dakar Plateau."
)
req_dakar.update!(status: "bidding")

# Offer on Lyon -> Montreal
Bid.create!(
  shipping_request: req_montreal,
  traveler: youssef,
  price_per_kg_euros: 11.00,
  available_kg: 15,
  travel_date: 17.days.from_now.to_date,
  flight_number: "TS111",
  message: "Direct Air Transat flight out of Lyon Saint-Exupéry."
)
req_montreal.update!(status: "bidding")

# Accepted shipment awaiting handover (to demonstrate secret codes)
req_active = ShippingRequest.create!(
  sender: marie,
  title: "Artisan textile samples to London",
  description: "Folded fabric swatches packed neatly in a 4 kg zippered garment sleeve.",
  weight_kg: 4.0,
  departure_city: "Paris", departure_country: "France",
  arrival_city: "London", arrival_country: "United Kingdom",
  desired_date: 5.days.from_now.to_date,
  max_budget_euros: 45,
  item_category: "clothing",
  prohibited_items_acknowledged: true
)
accepted_bid = Bid.create!(
  shipping_request: req_active,
  traveler: pierre,
  price_per_kg_euros: 8.50,
  available_kg: 10,
  travel_date: 5.days.from_now.to_date,
  flight_number: "BA307",
  message: "Morning flight from CDG Terminal 2C."
)
active_tracking = req_active.accept_bid!(accepted_bid)

# Completed shipment with mutual 5-star reviews
req_completed = ShippingRequest.create!(
  sender: marie,
  title: "Architecture books to Dakar",
  description: "Three hardcover design books wrapped securely.",
  weight_kg: 4.5,
  departure_city: "Paris", departure_country: "France",
  arrival_city: "Dakar", arrival_country: "Senegal",
  desired_date: 2.days.from_now.to_date,
  max_budget_euros: 60,
  item_category: "books",
  prohibited_items_acknowledged: true
)
completed_bid = Bid.create!(
  shipping_request: req_completed,
  traveler: pierre,
  price_per_kg_euros: 9.50,
  available_kg: 8,
  travel_date: 2.days.from_now.to_date,
  flight_number: "AF718",
  message: "Available for handover tomorrow afternoon."
)
completed_tracking = req_completed.accept_bid!(completed_bid)
completed_tracking.verify_and_hand_over!(completed_tracking.handover_code)
completed_tracking.mark_in_transit!
completed_tracking.verify_and_deliver!(completed_tracking.delivery_code)
completed_tracking.confirm!

Review.create!(
  shipping_request: req_completed,
  reviewer: marie,
  reviewee: pierre,
  rating: 5,
  comment: "Very reliable and punctual — delivered in perfect condition in Dakar.",
  role: "sender"
)
Review.create!(
  shipping_request: req_completed,
  reviewer: pierre,
  reviewee: marie,
  rating: 5,
  comment: "Well-packed parcel and smooth, responsive communication.",
  role: "traveler"
)

conv = Conversation.create!(sender: marie, recipient: pierre, shipping_request: req_active)
conv.messages.create!(sender: marie, body: "Hi Pierre, thanks for accepting! Could we meet Thursday at 6:30 PM near Châtelet?")
conv.messages.create!(sender: pierre, body: "Hi Marie, Thursday at 6:30 PM works great. I'll enter your handover code right when we meet.")

Notification.notify(marie, req_dakar, "new_bid", "Aminata Diallo offered €9.00/kg on “#{req_dakar.title}”")
Notification.notify(pierre, active_tracking, "bid_accepted", "Your offer for “#{req_active.title}” was accepted!")

puts "Seed complete: #{User.count} members, #{ShippingRequest.count} requests, #{Bid.count} offers, #{ShipmentTracking.count} trackings, #{Review.count} reviews."
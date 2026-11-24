# =============================================================================
# ShareMyBag Exchange (B2B Airline Baggage Allowance Exchange) — Realistic Seeds
# =============================================================================
puts "Seeding ShareMyBag B2B Airline Baggage Allowance Exchange..."

# Idempotent reset of exchange records so re-seeding always yields a clean live market
Notification.delete_all
KiloTrade.delete_all
KiloOrder.delete_all
PassengerBooking.delete_all
Flight.delete_all
AircraftType.delete_all
User.delete_all

# 1. Commercial Aircraft Types (certified baggage payload envelopes)
aircraft = {
  "A350-900" => AircraftType.create!(
    code: "A350-900",
    aircraft_name: "Airbus A350-900",
    manufacturer: "Airbus",
    seat_capacity: 324,
    default_baggage_kg_per_pax: 23.0,
    max_baggage_payload_kg: 7452.0,
    fuel_burn_rate_per_kg_hour: 0.035
  ),
  "B777-300ER" => AircraftType.create!(
    code: "B777-300ER",
    aircraft_name: "Boeing 777-300ER",
    manufacturer: "Boeing",
    seat_capacity: 381,
    default_baggage_kg_per_pax: 23.0,
    max_baggage_payload_kg: 8763.0,
    fuel_burn_rate_per_kg_hour: 0.036
  ),
  "A330-200" => AircraftType.create!(
    code: "A330-200",
    aircraft_name: "Airbus A330-200",
    manufacturer: "Airbus",
    seat_capacity: 277,
    default_baggage_kg_per_pax: 23.0,
    max_baggage_payload_kg: 6371.0,
    fuel_burn_rate_per_kg_hour: 0.035
  ),
  "B737-800" => AircraftType.create!(
    code: "B737-800",
    aircraft_name: "Boeing 737-800",
    manufacturer: "Boeing",
    seat_capacity: 186,
    default_baggage_kg_per_pax: 23.0,
    max_baggage_payload_kg: 4278.0,
    fuel_burn_rate_per_kg_hour: 0.034
  ),
  "A320neo" => AircraftType.create!(
    code: "A320neo",
    aircraft_name: "Airbus A320neo",
    manufacturer: "Airbus",
    seat_capacity: 180,
    default_baggage_kg_per_pax: 23.0,
    max_baggage_payload_kg: 4140.0,
    fuel_burn_rate_per_kg_hour: 0.032
  )
}

# 2. Demo Accounts + Co-Passengers
marie = User.create!(
  name: "Marie Laurent",
  email: "marie@example.com",
  password: "Marie123!",
  password_confirmation: "Marie123!",
  city: "Paris",
  country: "France",
  role: "passenger",
  bio: "Consulting partner flying light with cabin baggage on Paris–Dakar and London–Lagos routes."
)

pierre = User.create!(
  name: "Pierre Diallo",
  email: "pierre@example.com",
  password: "Pierre123!",
  password_confirmation: "Pierre123!",
  city: "Dakar",
  country: "Senegal",
  role: "passenger",
  bio: "Hardware engineer regularly checking exhibition equipment and family gifts."
)

vp_airline = User.create!(
  name: "Claire Delacroix",
  email: "vp@airfrance-demo.com",
  password: "Airline123!",
  password_confirmation: "Airline123!",
  city: "Roissy-en-France",
  country: "France",
  role: "airline_admin",
  bio: "VP Ancillary Revenue & Digital Distribution."
)

co_pax_specs = [
  ["Amadou Ndiaye", "amadou@demo.com", "Dakar", "Senegal"],
  ["Sophie Bernard", "sophie@demo.com", "Paris", "France"],
  ["David Okafor", "david@demo.com", "London", "United Kingdom"],
  ["Fatou Sow", "fatou@demo.com", "Lyon", "France"],
  ["Marc Tremblay", "marc@demo.com", "Montreal", "Canada"],
  ["Nadia Benali", "nadia@demo.com", "Casablanca", "Morocco"],
  ["Karim Mansour", "karim@demo.com", "Marseille", "France"],
  ["Elena Rossi", "elena@demo.com", "Paris", "France"],
  ["James Wright", "james@demo.com", "London", "United Kingdom"],
  ["Amina Toure", "amina@demo.com", "Dakar", "Senegal"],
  ["Lucas Moreau", "lucas@demo.com", "Lyon", "France"],
  ["Yasmine Haddad", "yasmine@demo.com", "Tunis", "Tunisia"]
]

co_pax = co_pax_specs.map do |name, email, city, country|
  User.create!(
    name: name,
    email: email,
    password: "DemoUser123!",
    password_confirmation: "DemoUser123!",
    city: city,
    country: country,
    role: "passenger"
  )
end

# 3. Five Live Commercial Flights (T-48h to T-4h open window)
af718 = Flight.create!(
  flight_number: "AF718",
  airline_name: "Air France",
  airline_code: "AF",
  aircraft_type: aircraft["A350-900"],
  departure_iata: "CDG",
  departure_city: "Paris",
  arrival_iata: "DKR",
  arrival_city: "Dakar",
  departure_at: 18.hours.from_now,
  flight_duration_hours: 5.5,
  airport_excess_fee_per_kg_cents: 1500,
  airline_commission_bps: 2500,
  base_booked_baggage_kg: 5680.0,
  status: "open"
)

ba075 = Flight.create!(
  flight_number: "BA075",
  airline_name: "British Airways",
  airline_code: "BA",
  aircraft_type: aircraft["B777-300ER"],
  departure_iata: "LHR",
  departure_city: "London",
  arrival_iata: "LOS",
  arrival_city: "Lagos",
  departure_at: 22.hours.from_now,
  flight_duration_hours: 6.5,
  airport_excess_fee_per_kg_cents: 1600,
  airline_commission_bps: 2500,
  base_booked_baggage_kg: 6890.0,
  status: "open"
)

ts111 = Flight.create!(
  flight_number: "TS111",
  airline_name: "Air Transat",
  airline_code: "TS",
  aircraft_type: aircraft["A330-200"],
  departure_iata: "LYS",
  departure_city: "Lyon",
  arrival_iata: "YUL",
  arrival_city: "Montreal",
  departure_at: 28.hours.from_now,
  flight_duration_hours: 7.5,
  airport_excess_fee_per_kg_cents: 1400,
  airline_commission_bps: 2500,
  base_booked_baggage_kg: 4410.0,
  status: "open"
)

at771 = Flight.create!(
  flight_number: "AT771",
  airline_name: "Royal Air Maroc",
  airline_code: "AT",
  aircraft_type: aircraft["B737-800"],
  departure_iata: "ORY",
  departure_city: "Paris Orly",
  arrival_iata: "CMN",
  arrival_city: "Casablanca",
  departure_at: 15.hours.from_now,
  flight_duration_hours: 3.1,
  airport_excess_fee_per_kg_cents: 1200,
  airline_commission_bps: 2500,
  base_booked_baggage_kg: 3120.0,
  status: "open"
)

tu721 = Flight.create!(
  flight_number: "TU721",
  airline_name: "Tunisair",
  airline_code: "TU",
  aircraft_type: aircraft["A320neo"],
  departure_iata: "MRS",
  departure_city: "Marseille",
  arrival_iata: "TUN",
  arrival_city: "Tunis",
  departure_at: 34.hours.from_now,
  flight_duration_hours: 1.8,
  airport_excess_fee_per_kg_cents: 1100,
  airline_commission_bps: 2500,
  base_booked_baggage_kg: 2760.0,
  status: "open"
)

# Realistic adverse-state flight: past H-4h Weight & Balance cutoff with long carrier/city names
sn372 = Flight.create!(
  flight_number: "SN372",
  airline_name: "Brussels Airlines — Intercontinental",
  airline_code: "SN",
  aircraft_type: aircraft["A330-200"],
  departure_iata: "BRU",
  departure_city: "Brussels National",
  arrival_iata: "FIH",
  arrival_city: "Kinshasa N'Djili",
  departure_at: 2.5.hours.from_now,
  flight_duration_hours: 8.2,
  airport_excess_fee_per_kg_cents: 1600,
  airline_commission_bps: 2500,
  base_booked_baggage_kg: 4820.0,
  status: "open"
)

# Helper to book a passenger on a flight
def book!(user, flight, pnr, cabin: "economy")
  PassengerBooking.create!(
    user: user,
    flight: flight,
    pnr_code: pnr,
    cabin_class: cabin,
    base_allowance_kg: 23.0,
    current_allowance_kg: 23.0,
    max_allowance_kg: 46.0
  )
end

# 4. Seed Demo Bookings (Marie, Pierre & VP pre-booked on AF718 + secondary flights)
book!(marie, af718, "AF718M")
book!(pierre, af718, "AF718P")
book!(vp_airline, af718, "AF718V", cabin: "business")
book!(marie, ba075, "BA075M")
book!(marie, at771, "AT771M")
book!(pierre, ts111, "TS111P")
book!(pierre, tu721, "TU721P")

# 5. Seed Realistic Order Books & Executed Trades through the Real Matching Engine
def seed_flight_market!(flight:, users:, executed_pairs:, resting_bids:, resting_asks:)
  bookings = {}
  users.each_with_index do |u, idx|
    pnr = "#{flight.airline_code}#{flight.id}P#{format('%02d', idx + 1)}"
    bookings[u.id] = book!(u, flight, pnr)
  end

  executed_pairs.each do |seller_idx, buyer_idx, qty, price_cents, payout|
    seller = users[seller_idx]
    buyer  = users[buyer_idx]
    OrderBookMatchingService.place_and_match!(
      flight: flight,
      booking: bookings[seller.id],
      user: seller,
      side: "sell",
      quantity_kg: qty,
      price_per_kg_cents: price_cents,
      payout_preference: payout
    )
    OrderBookMatchingService.place_and_match!(
      flight: flight,
      booking: bookings[buyer.id],
      user: buyer,
      side: "buy",
      quantity_kg: qty,
      price_per_kg_cents: price_cents
    )
  end

  resting_bids.each do |user_idx, qty, price_cents|
    u = users[user_idx]
    OrderBookMatchingService.place_and_match!(
      flight: flight,
      booking: bookings[u.id],
      user: u,
      side: "buy",
      quantity_kg: qty,
      price_per_kg_cents: price_cents
    )
  end

  resting_asks.each do |user_idx, qty, price_cents, payout|
    u = users[user_idx]
    OrderBookMatchingService.place_and_match!(
      flight: flight,
      booking: bookings[u.id],
      user: u,
      side: "sell",
      quantity_kg: qty,
      price_per_kg_cents: price_cents,
      payout_preference: payout
    )
  end
end

# AF718 (CDG -> DKR): vibrant flagship flight!
seed_flight_market!(
  flight: af718,
  users: co_pax[0..9],
  executed_pairs: [
    [0, 1, 10, 750, "voucher"],
    [2, 3, 12, 800, "voucher"],
    [4, 5, 9,  750, "cash"],
    [6, 7, 14, 800, "voucher"]
  ],
  resting_bids: [
    [1, 8,  750],
    [3, 10, 700],
    [5, 12, 650],
    [8, 9,  600]
  ],
  resting_asks: [
    [0, 7,  800, "voucher"],
    [2, 9,  850, "voucher"],
    [4, 8,  900, "cash"],
    [9, 11, 950, "voucher"]
  ]
)

# BA075 (LHR -> LOS)
seed_flight_market!(
  flight: ba075,
  users: co_pax[0..7],
  executed_pairs: [
    [0, 1, 15, 850, "voucher"],
    [2, 3, 12, 900, "voucher"],
    [4, 5, 11, 850, "cash"]
  ],
  resting_bids: [
    [1, 7, 850],
    [3, 9, 800],
    [6, 10, 750]
  ],
  resting_asks: [
    [0, 6, 900, "voucher"],
    [2, 8, 950, "voucher"],
    [7, 12, 1000, "voucher"]
  ]
)

# TS111 (LYS -> YUL)
seed_flight_market!(
  flight: ts111,
  users: co_pax[4..11],
  executed_pairs: [
    [0, 1, 10, 700, "voucher"],
    [2, 3, 14, 750, "voucher"]
  ],
  resting_bids: [
    [1, 8, 700],
    [4, 10, 650]
  ],
  resting_asks: [
    [0, 9, 750, "voucher"],
    [5, 11, 800, "cash"]
  ]
)

# AT771 (ORY -> CMN)
seed_flight_market!(
  flight: at771,
  users: co_pax[2..9],
  executed_pairs: [
    [0, 1, 11, 600, "voucher"],
    [2, 3, 10, 650, "voucher"],
    [4, 5, 8,  600, "cash"]
  ],
  resting_bids: [
    [1, 9, 600],
    [6, 8, 550]
  ],
  resting_asks: [
    [0, 8, 650, "voucher"],
    [7, 10, 700, "voucher"]
  ]
)

# TU721 (MRS -> TUN)
seed_flight_market!(
  flight: tu721,
  users: co_pax[0..5],
  executed_pairs: [
    [0, 1, 10, 550, "voucher"],
    [2, 3, 9,  600, "voucher"]
  ],
  resting_bids: [
    [1, 7, 550],
    [4, 9, 500]
  ],
  resting_asks: [
    [0, 8, 600, "voucher"],
    [5, 10, 650, "voucher"]
  ]
)

fleet = AirlineEconomicsService.fleet_summary(Flight.all)
puts "Seeded #{AircraftType.count} aircraft types, #{Flight.count} live flights, #{PassengerBooking.count} PNRs, #{KiloOrder.count} orders, #{KiloTrade.count} executed trades (#{fleet[:matched_kg]} kg, airline net margin €#{format('%.2f', fleet[:airline_net_margin_cents] / 100.0)})."
puts "Demo accounts: marie@example.com / Marie123! | pierre@example.com / Pierre123! | vp@airfrance-demo.com / Airline123!"
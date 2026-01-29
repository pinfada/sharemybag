FactoryBot.define do
  factory :marketplace_user, class: 'User' do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password1" }
    password_confirmation { "Password1" }
    vol { nil }
    admin { false }
    country { "FR" }
    phone { "+33612345678" }
  end

  factory :admin_user, class: 'User' do
    sequence(:name) { |n| "Admin #{n}" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { "Password1" }
    password_confirmation { "Password1" }
    vol { nil }
    admin { true }
    country { "FR" }
  end

  factory :shipping_request do
    association :sender, factory: :marketplace_user
    sequence(:title) { |n| "Shipping Request #{n}" }
    description { "Test shipping request description" }
    weight_kg { 5.0 }
    departure_city { "Paris" }
    departure_country { "FR" }
    arrival_city { "New York" }
    arrival_country { "US" }
    desired_date { 30.days.from_now }
    currency { "EUR" }
    status { "open" }
    max_budget_cents { 5000 }
  end

  factory :bid do
    association :shipping_request
    association :traveler, factory: :marketplace_user
    price_per_kg_cents { 500 }
    available_kg { 10.0 }
    travel_date { 30.days.from_now }
    currency { "EUR" }
    status { "pending" }
  end

  factory :kilo_offer do
    association :traveler, factory: :marketplace_user
    departure_city { "Paris" }
    departure_country { "FR" }
    arrival_city { "New York" }
    arrival_country { "US" }
    travel_date { 30.days.from_now }
    available_kg { 10.0 }
    price_per_kg_cents { 500 }
    currency { "EUR" }
    status { "active" }
    flight_number { "AF1234" }
  end

  factory :marketplace_transaction, class: 'Transaction' do
    association :shipping_request
    association :bid
    association :sender, factory: :marketplace_user
    association :traveler, factory: :marketplace_user
    amount_cents { 2500 }
    platform_fee_cents { 375 }
    traveler_payout_cents { 2125 }
    currency { "EUR" }
    status { "pending" }
  end

  factory :shipment_tracking do
    association :shipping_request
    association :traveler, factory: :marketplace_user
    status { "created" }
  end

  factory :identity_verification do
    association :user, factory: :marketplace_user
    document_type { "passport" }
    status { "pending" }
  end

  factory :notification do
    association :user, factory: :marketplace_user
    association :notifiable, factory: :shipping_request
    action { "test_action" }
    message { "Test notification message" }
    read { false }
  end

  factory :flight_verification do
    association :kilo_offer
    association :user, factory: :marketplace_user
    flight_number { "AF1234" }
    departure_airport { "CDG" }
    arrival_airport { "JFK" }
    departure_date { 30.days.from_now }
    status { "pending" }
  end

  factory :delivery_confirmation do
    association :shipment_tracking
    association :sender, factory: :marketplace_user
    association :traveler, factory: :marketplace_user
    otp_digest { BCrypt::Password.create("123456") }
    otp_generated_at { Time.current }
    otp_expires_at { 30.minutes.from_now }
    attempts_count { 0 }
    max_attempts { 3 }
    blocked { false }
    notification_channel { "sms" }
  end

  factory :dispute do
    association :shipping_request
    association :transaction, factory: :marketplace_transaction
    association :opened_by, factory: :marketplace_user
    dispute_type { "damaged" }
    title { "Package was damaged" }
    description { "The package arrived with visible damage to the exterior." }
    status { "opened" }
    priority { "normal" }
    auto_escalate_at { 72.hours.from_now }
    response_deadline_at { 48.hours.from_now }
    last_activity_at { Time.current }
  end

  factory :dispute_evidence do
    association :dispute
    association :submitted_by, factory: :marketplace_user
    evidence_type { "photo" }
    file_url { "https://example.com/evidence/photo1.jpg" }
    description { "Photo of damaged package" }
    content_hash { Digest::SHA256.hexdigest("https://example.com/evidence/photo1.jpg") }
  end

  factory :dispute_message do
    association :dispute
    association :sender, factory: :marketplace_user
    body { "This is a dispute message" }
    is_internal { false }
  end

  factory :stripe_webhook_event do
    sequence(:stripe_event_id) { |n| "evt_test_#{n}" }
    event_type { "payment_intent.succeeded" }
    payload { { test: true } }
    processed { false }
  end

  factory :payment_audit_log do
    association :transaction, factory: :marketplace_transaction
    association :user, factory: :marketplace_user
    action { "payment_initiated" }
    status { "success" }
    amount_cents { 2500 }
    currency { "EUR" }
  end
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  def create_user(attrs = {})
    seq = next_seq
    defaults = {
      name: "Passenger #{seq}",
      email: "passenger#{seq}@example.com",
      password: "Password123",
      password_confirmation: "Password123",
      city: "Paris",
      country: "France",
      currency: "EUR",
      role: "passenger",
      voucher_balance_cents: 0
    }
    User.create!(defaults.merge(attrs))
  end

  def create_aircraft_type(attrs = {})
    seq = next_seq
    defaults = {
      code: "A350-#{seq.delete('_').last(8)}",
      aircraft_name: "Airbus A350-900",
      manufacturer: "Airbus",
      seat_capacity: 324,
      default_baggage_kg_per_pax: 23.0,
      max_baggage_payload_kg: 7452.0,
      fuel_burn_rate_per_kg_hour: 0.035
    }
    AircraftType.create!(defaults.merge(attrs))
  end

  def create_flight(aircraft_type: nil, **attrs)
    aircraft_type ||= create_aircraft_type
    defaults = {
      flight_number: "AF718",
      airline_name: "Air France",
      airline_code: "AF",
      aircraft_type: aircraft_type,
      departure_iata: "CDG",
      departure_city: "Paris",
      arrival_iata: "DKR",
      arrival_city: "Dakar",
      departure_at: 24.hours.from_now,
      flight_duration_hours: 5.5,
      airport_excess_fee_per_kg_cents: 1500,
      airline_commission_bps: 2500,
      base_booked_baggage_kg: 5200.0,
      status: "open"
    }
    Flight.create!(defaults.merge(attrs))
  end

  def create_booking(user: nil, flight: nil, **attrs)
    user ||= create_user
    flight ||= create_flight
    seq = next_seq
    defaults = {
      pnr_code: "P#{seq.delete('_').last(5).upcase}",
      user: user,
      flight: flight,
      cabin_class: "economy",
      base_allowance_kg: 23.0,
      current_allowance_kg: 23.0,
      max_allowance_kg: 46.0
    }
    PassengerBooking.create!(defaults.merge(attrs))
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

require "test_helper"

class PassengerBookingAndOrderTest < ActiveSupport::TestCase
  test "prevents double-selling beyond available_to_sell_kg" do
    flight = create_flight
    seller = create_user
    booking = create_booking(user: seller, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 23.0)

    first_ask = KiloOrder.create!(
      flight: flight,
      passenger_booking: booking,
      user: seller,
      side: "sell",
      quantity_kg: 15.0,
      remaining_kg: 15.0,
      price_per_kg_cents: 700,
      payout_preference: "voucher"
    )
    assert first_ask.persisted?
    assert_in_delta 8.0, booking.reload.available_to_sell_kg, 0.01

    overdraft_ask = KiloOrder.new(
      flight: flight,
      passenger_booking: booking,
      user: seller,
      side: "sell",
      quantity_kg: 10.0,
      remaining_kg: 10.0,
      price_per_kg_cents: 750,
      payout_preference: "voucher"
    )
    assert_not overdraft_ask.valid?
    assert overdraft_ask.errors[:quantity_kg].any?
  end

  test "prevents buying above PNR max_allowance_kg (46 kg / 2 bags cap)" do
    flight = create_flight
    buyer = create_user
    booking = create_booking(user: buyer, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 40.0, max_allowance_kg: 46.0)

    assert_in_delta 6.0, booking.available_to_buy_kg, 0.01

    excess_bid = KiloOrder.new(
      flight: flight,
      passenger_booking: booking,
      user: buyer,
      side: "buy",
      quantity_kg: 8.0,
      remaining_kg: 8.0,
      price_per_kg_cents: 700,
      payout_preference: "voucher"
    )
    assert_not excess_bid.valid?
    assert excess_bid.errors[:quantity_kg].any?
  end

  test "forbids holding simultaneous open buy and sell orders on the same flight (anti-wash-trading)" do
    flight = create_flight
    user = create_user
    booking = create_booking(user: user, flight: flight)

    KiloOrder.create!(
      flight: flight,
      passenger_booking: booking,
      user: user,
      side: "sell",
      quantity_kg: 5.0,
      remaining_kg: 5.0,
      price_per_kg_cents: 800,
      payout_preference: "voucher"
    )

    opposite = KiloOrder.new(
      flight: flight,
      passenger_booking: booking,
      user: user,
      side: "buy",
      quantity_kg: 5.0,
      remaining_kg: 5.0,
      price_per_kg_cents: 750,
      payout_preference: "voucher"
    )
    assert_not opposite.valid?
    assert opposite.errors[:base].any?
  end

  test "rejects order using another user's passenger booking or closed flight" do
    flight = create_flight
    owner = create_user
    intruder = create_user
    owner_booking = create_booking(user: owner, flight: flight)

    hijack = KiloOrder.new(
      flight: flight,
      passenger_booking: owner_booking,
      user: intruder,
      side: "sell",
      quantity_kg: 5.0,
      remaining_kg: 5.0,
      price_per_kg_cents: 700,
      payout_preference: "voucher"
    )
    assert_not hijack.valid?
    assert hijack.errors[:passenger_booking].any?

    late_flight = create_flight(departure_at: 2.hours.from_now, status: "open")
    late_booking = create_booking(user: owner, flight: late_flight)
    late_order = KiloOrder.new(
      flight: late_flight,
      passenger_booking: late_booking,
      user: owner,
      side: "sell",
      quantity_kg: 5.0,
      remaining_kg: 5.0,
      price_per_kg_cents: 700,
      payout_preference: "voucher"
    )
    assert_not late_order.valid?
    assert late_order.errors[:base].any?
  end

  test "converts price_per_kg_euros cleanly and flags IATA 32 kg split bag requirement" do
    flight = create_flight
    user = create_user
    booking = create_booking(user: user, flight: flight, base_allowance_kg: 23.0, current_allowance_kg: 35.0)
    assert booking.requires_split_bags?

    order = KiloOrder.new(
      flight: flight,
      passenger_booking: booking,
      user: user,
      side: "sell",
      quantity_kg: 5.0,
      price_per_kg_euros: "7.50",
      payout_preference: "voucher"
    )
    assert order.valid?
    assert_equal 750, order.price_per_kg_cents
    assert_in_delta 5.0, order.remaining_kg.to_f, 0.01
  end
end

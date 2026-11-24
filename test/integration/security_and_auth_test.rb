require "test_helper"

class SecurityAndAuthTest < ActionDispatch::IntegrationTest
  test "sends hardened OWASP security headers and strict CSP on every response" do
    get root_path
    assert_response :success
    assert_equal "DENY", response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
    assert_includes response.headers["Permissions-Policy"].to_s, "camera=()"
    assert_includes response.headers["Content-Security-Policy"].to_s, "default-src 'self'"
    assert_includes response.headers["Content-Security-Policy"].to_s, "frame-ancestors 'none'"
  end

  test "sign up, secure HttpOnly/SameSite=Lax cookie, and sign out with remember_token rotation" do
    post users_path, params: {
      user: {
        name: "Claire Moreau",
        email: "claire@example.com",
        password: "Password123",
        password_confirmation: "Password123",
        city: "Paris",
        country: "France"
      }
    }
    assert_redirected_to flights_path
    set_cookie = response.headers["Set-Cookie"].to_s
    assert_match(/remember_token=/i, set_cookie)
    assert_match(/httponly/i, set_cookie)
    assert_match(/samesite=lax/i, set_cookie)

    user = User.find_by!(email: "claire@example.com")
    old_digest = user.remember_token

    delete signout_path
    assert_redirected_to root_url
    assert_not_equal old_digest, user.reload.remember_token
  end

  test "handles malformed or invalid login params without 500 error" do
    post sessions_path, params: {}
    assert_response :unprocessable_entity

    post sessions_path, params: { session: { email: "unknown@example.com", password: "Wrong123" } }
    assert_response :unprocessable_entity
  end

  test "public profile never leaks another user's email address or PNR codes and blocks unauthorized edits" do
    alice = create_user(name: "Alice Dupont", email: "alice.secret@example.com")
    bob = create_user(name: "Bob Martin", email: "bob@example.com")
    flight = create_flight
    create_booking(user: alice, flight: flight, pnr_code: "ALICE9")

    get user_path(alice)
    assert_response :success
    assert_includes response.body, "Alice Dupont"
    assert_not_includes response.body, "alice.secret@example.com"
    assert_not_includes response.body, "ALICE9"

    sign_in_as(bob)
    get user_path(alice)
    assert_response :success
    assert_not_includes response.body, "alice.secret@example.com"
    assert_not_includes response.body, "ALICE9"

    patch user_path(alice), params: { user: { name: "Hacked" } }
    assert_redirected_to root_url
    assert_equal "Alice Dupont", alice.reload.name
  end

  test "anti-IDOR: another passenger cannot cancel someone else's order or place an order without a booking on the flight" do
    flight = create_flight
    alice = create_user(name: "Alice Light")
    bob = create_user(name: "Bob Intruder")
    alice_booking = create_booking(user: alice, flight: flight, pnr_code: "AF718A")

    alice_order = OrderBookMatchingService.place_and_match!(
      flight: flight,
      booking: alice_booking,
      user: alice,
      side: "sell",
      quantity_kg: 8.0,
      price_per_kg_cents: 700
    ).order

    sign_in_as(bob)

    # Bob has no booking on this flight -> cannot place order
    assert_no_difference "KiloOrder.count" do
      post flight_kilo_orders_path(flight), params: {
        kilo_order: {
          side: "sell",
          quantity_kg: 5,
          price_per_kg_euros: "6.50",
          payout_preference: "voucher"
        }
      }
    end
    assert_redirected_to flight_path(flight)

    # Bob cannot cancel Alice's order
    patch cancel_flight_kilo_order_path(flight, alice_order)
    assert_redirected_to flight_path(flight)
    assert_equal "open", alice_order.reload.status
  end

  test "redirects back to protected internal page after login (no open redirect)" do
    user = create_user
    get my_bookings_path
    assert_redirected_to signin_url

    post sessions_path, params: { session: { email: user.email, password: "Password123" } }
    assert_redirected_to my_bookings_path
  end
end

require 'test_helper'

class SecurityAndAuthTest < ActionDispatch::IntegrationTest
  test "envoie les en-têtes de sécurité OWASP et CSP sur les réponses" do
    get root_path
    assert_response :success
    assert_equal "DENY", response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
    assert_includes response.headers["Permissions-Policy"].to_s, "camera=()"
    assert_includes response.headers["Content-Security-Policy"].to_s, "default-src 'self'"
    assert_includes response.headers["Content-Security-Policy"].to_s, "frame-ancestors 'none'"
  end

  test "inscription, connexion sécurisée (cookie HttpOnly + SameSite=Lax) et déconnexion" do
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
    assert_redirected_to shipping_requests_path
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

  test "résiste à des paramètres de connexion absents ou invalides sans erreur 500" do
    post sessions_path, params: {}
    assert_response :unprocessable_entity

    post sessions_path, params: { session: { email: "inconnu@example.com", password: "Wrong123" } }
    assert_response :unprocessable_entity
  end

  test "le profil public ne divulgue jamais l'adresse email d'un autre utilisateur" do
    alice = create_user(name: "Alice Dupont", email: "alice.secret@example.com")
    bob = create_user(name: "Bob Martin", email: "bob@example.com")

    # Visiteur anonyme
    get user_path(alice)
    assert_response :success
    assert_includes response.body, "Alice Dupont"
    assert_not_includes response.body, "alice.secret@example.com"

    # Autre utilisateur connecté
    sign_in_as(bob)
    get user_path(alice)
    assert_response :success
    assert_not_includes response.body, "alice.secret@example.com"

    # Autre utilisateur ne peut pas modifier le profil d'Alice
    patch user_path(alice), params: { user: { name: "Piraté" } }
    assert_redirected_to root_url
    assert_equal "Alice Dupont", alice.reload.name
  end

  test "un utilisateur peut modifier son propre profil sans changer son mot de passe" do
    alice = create_user(name: "Alice Dupont", city: "Paris")
    sign_in_as(alice)

    patch user_path(alice), params: { user: { name: "Alice D.", city: "Bordeaux", bio: "Voyage souvent" } }
    assert_redirected_to user_path(alice)
    alice.reload
    assert_equal "Alice D.", alice.name
    assert_equal "Bordeaux", alice.city
    assert_equal "Voyage souvent", alice.bio
  end

  test "refuse les redirections ouvertes après authentification" do
    user = create_user
    get signin_path
    # Simuler un accès protégé interne légitime
    get new_shipping_request_path
    assert_redirected_to signin_url

    post sessions_path, params: { session: { email: user.email, password: "Password123" } }
    assert_redirected_to new_shipping_request_path
  end
end

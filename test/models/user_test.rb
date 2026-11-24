require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid passenger user with strong password" do
    user = create_user(name: "Marie Laurent", email: "MARIE@Example.COM")
    assert user.valid?
    assert_equal "marie@example.com", user.email
    assert_equal "passenger", user.role
    assert_equal 0, user.voucher_balance_cents
    assert_not user.airline_admin?
    assert user.remember_token.present?
  end

  test "airline admin role predicate" do
    admin = create_user(role: "airline_admin")
    assert admin.airline_admin?
  end

  test "rejects invalid role" do
    user = User.new(
      name: "Bad Role",
      email: "badrole@example.com",
      password: "Password123",
      password_confirmation: "Password123",
      role: "superhacker"
    )
    assert_not user.valid?
    assert user.errors[:role].any?
  end

  test "rejects weak passwords" do
    user = User.new(
      name: "Weak Pass",
      email: "weak@example.com",
      password: "password",
      password_confirmation: "password"
    )
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "profile can be updated without changing password" do
    user = create_user
    assert user.update(city: "Lyon", bio: "Frequent flyer")
    assert_equal "Lyon", user.reload.city
  end

  test "voucher_balance_euros formats cents accurately" do
    user = create_user(voucher_balance_cents: 6550)
    assert_in_delta 65.50, user.voucher_balance_euros, 0.001
  end

  test "User.digest returns nil for blank tokens and SHA256 hex otherwise" do
    assert_nil User.digest(nil)
    assert_nil User.digest("")
    digest = User.digest("secret-token")
    assert_equal 64, digest.length
  end
end

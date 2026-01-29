class StripeConnectService
  class ConnectError < StandardError; end

  def initialize(user)
    @user = user
  end

  # Create Stripe Express account for a traveler
  def create_account!
    return if @user.stripe_account_id.present?

    account = Stripe::Account.create(
      type: 'express',
      country: @user.country.presence || 'FR',
      email: @user.email,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true }
      },
      business_type: 'individual',
      individual: {
        email: @user.email,
        first_name: @user.name.split(' ').first,
        last_name: @user.name.split(' ').drop(1).join(' ').presence
      }.compact,
      metadata: { user_id: @user.id, platform: 'sharemybag' }
    )

    @user.update!(
      stripe_account_id: account.id,
      stripe_account_status: "pending"
    )

    account
  rescue Stripe::StripeError => e
    raise ConnectError, "Account creation failed: #{e.message}"
  end

  # Generate onboarding link
  def create_onboarding_link!(return_url:, refresh_url:)
    ensure_account_exists!

    Stripe::AccountLink.create(
      account: @user.stripe_account_id,
      return_url: return_url,
      refresh_url: refresh_url,
      type: 'account_onboarding'
    )
  rescue Stripe::StripeError => e
    raise ConnectError, "Onboarding link failed: #{e.message}"
  end

  # Generate dashboard login link for traveler
  def create_dashboard_link!
    ensure_account_exists!

    Stripe::Account.create_login_link(@user.stripe_account_id)
  rescue Stripe::StripeError => e
    raise ConnectError, "Dashboard link failed: #{e.message}"
  end

  # Check account status
  def sync_account_status!
    ensure_account_exists!

    account = Stripe::Account.retrieve(@user.stripe_account_id)

    status = if account.charges_enabled && account.payouts_enabled
               "active"
             elsif account.requirements&.disabled_reason.present?
               "disabled"
             elsif account.requirements&.currently_due&.any?
               "restricted"
             else
               "pending"
             end

    @user.update!(
      stripe_account_status: status,
      stripe_onboarding_completed: account.charges_enabled && account.payouts_enabled
    )

    status
  rescue Stripe::StripeError => e
    raise ConnectError, "Status sync failed: #{e.message}"
  end

  # Get account balance
  def account_balance
    ensure_account_exists!
    Stripe::Balance.retrieve({ stripe_account: @user.stripe_account_id })
  rescue Stripe::StripeError => e
    raise ConnectError, "Balance retrieval failed: #{e.message}"
  end

  private

  def ensure_account_exists!
    raise ConnectError, "No Stripe account for user #{@user.id}" unless @user.stripe_account_id.present?
  end
end

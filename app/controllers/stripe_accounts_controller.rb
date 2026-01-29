class StripeAccountsController < ApplicationController
  before_action :signed_in_user

  # GET /stripe_account/onboarding
  def onboarding
    service = StripeConnectService.new(current_user)

    begin
      service.create_account! unless current_user.stripe_account_id.present?

      link = service.create_onboarding_link!(
        return_url: stripe_account_return_url(host: request.host_with_port),
        refresh_url: stripe_account_refresh_url(host: request.host_with_port)
      )

      redirect_to link.url, allow_other_host: true, status: :see_other
    rescue StripeConnectService::ConnectError => e
      flash[:error] = I18n.t('stripe_accounts.onboarding_error', message: e.message)
      redirect_to current_user
    end
  end

  # GET /stripe_account/return
  def return_from_onboarding
    service = StripeConnectService.new(current_user)
    status = service.sync_account_status!

    if status == "active"
      flash[:success] = I18n.t('stripe_accounts.onboarding_complete')
    else
      flash[:notice] = I18n.t('stripe_accounts.onboarding_incomplete')
    end

    redirect_to current_user
  rescue StripeConnectService::ConnectError => e
    flash[:error] = e.message
    redirect_to current_user
  end

  # GET /stripe_account/refresh
  def refresh
    redirect_to action: :onboarding
  end

  # GET /stripe_account/dashboard
  def dashboard
    if current_user.stripe_account_id.present?
      service = StripeConnectService.new(current_user)
      link = service.create_dashboard_link!
      redirect_to link.url, allow_other_host: true, status: :see_other
    else
      flash[:notice] = I18n.t('stripe_accounts.no_account')
      redirect_to action: :onboarding
    end
  rescue StripeConnectService::ConnectError => e
    flash[:error] = e.message
    redirect_to current_user
  end

  # GET /stripe_account/status
  def status
    if current_user.stripe_account_id.present?
      service = StripeConnectService.new(current_user)
      @status = service.sync_account_status!
    end

    render json: {
      has_account: current_user.stripe_account_id.present?,
      status: current_user.stripe_account_status,
      onboarding_completed: current_user.stripe_onboarding_completed
    }
  end
end

class SyncStripeAccountJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(user_id)
    user = User.find(user_id)
    return unless user.stripe_account_id.present?

    service = StripeConnectService.new(user)
    service.sync_account_status!
  rescue StripeConnectService::ConnectError => e
    Rails.logger.error("[SyncStripeAccountJob] Failed for User##{user_id}: #{e.message}")
  end
end

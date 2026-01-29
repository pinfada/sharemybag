module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :set_locale

    # POST /webhooks/stripe
    def create
      payload = request.body.read
      signature = request.env['HTTP_STRIPE_SIGNATURE']

      begin
        service = StripeWebhookService.new(payload, signature)
        service.process!
        head :ok
      rescue StripeWebhookService::WebhookError => e
        Rails.logger.error("Stripe webhook error: #{e.message}")
        head :bad_request
      rescue => e
        Rails.logger.error("Stripe webhook processing error: #{e.message}")
        head :internal_server_error
      end
    end
  end
end

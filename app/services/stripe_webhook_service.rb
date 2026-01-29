class StripeWebhookService
  class WebhookError < StandardError; end

  HANDLED_EVENTS = %w[
    payment_intent.succeeded
    payment_intent.payment_failed
    payment_intent.canceled
    checkout.session.completed
    charge.refunded
    charge.dispute.created
    transfer.created
    transfer.failed
    account.updated
    identity.verification_session.verified
    identity.verification_session.requires_input
  ].freeze

  def initialize(payload, signature)
    @payload = payload
    @signature = signature
  end

  def process!
    event = verify_signature!

    return if already_processed?(event.id)

    record = record_event!(event)

    begin
      handle_event(event)
      record.update!(processed: true, processed_at: Time.current)
    rescue => e
      record.update!(processing_errors: e.message)
      raise
    end
  end

  private

  def verify_signature!
    webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) ||
                     ENV['STRIPE_WEBHOOK_SECRET']

    Stripe::Webhook.construct_event(@payload, @signature, webhook_secret)
  rescue Stripe::SignatureVerificationError => e
    raise WebhookError, "Invalid signature: #{e.message}"
  rescue JSON::ParserError => e
    raise WebhookError, "Invalid payload: #{e.message}"
  end

  def already_processed?(event_id)
    StripeWebhookEvent.exists?(stripe_event_id: event_id, processed: true)
  end

  def record_event!(event)
    StripeWebhookEvent.create!(
      stripe_event_id: event.id,
      event_type: event.type,
      payload: event.data.to_h
    )
  rescue ActiveRecord::RecordNotUnique
    StripeWebhookEvent.find_by!(stripe_event_id: event.id)
  end

  def handle_event(event)
    case event.type
    when 'checkout.session.completed'
      handle_checkout_completed(event.data.object)
    when 'payment_intent.succeeded'
      handle_payment_succeeded(event.data.object)
    when 'payment_intent.payment_failed'
      handle_payment_failed(event.data.object)
    when 'charge.refunded'
      handle_charge_refunded(event.data.object)
    when 'charge.dispute.created'
      handle_dispute_created(event.data.object)
    when 'transfer.created'
      handle_transfer_created(event.data.object)
    when 'account.updated'
      handle_account_updated(event.data.object)
    when 'identity.verification_session.verified'
      handle_identity_verified(event.data.object)
    when 'identity.verification_session.requires_input'
      handle_identity_requires_input(event.data.object)
    else
      Rails.logger.info("Unhandled Stripe event: #{event.type}")
    end
  end

  def handle_checkout_completed(session)
    transaction = Transaction.find_by(
      "metadata->>'checkout_session_id' = ?", session.id
    ) || Transaction.find_by(id: session.metadata&.transaction_id)

    return unless transaction

    if session.payment_intent.present?
      transaction.update!(stripe_payment_intent_id: session.payment_intent)
      StripePaymentService.new(transaction).capture_payment!
    end
  end

  def handle_payment_succeeded(payment_intent)
    transaction = Transaction.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless transaction
    return if transaction.status.in?(%w[escrow released])

    transaction.pay!
    transaction.update!(stripe_charge_id: payment_intent.latest_charge)

    Notification.notify(
      transaction.sender,
      transaction,
      "payment_confirmed",
      "Payment of #{transaction.amount} #{transaction.currency} confirmed"
    )
  end

  def handle_payment_failed(payment_intent)
    transaction = Transaction.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless transaction

    transaction.update!(
      failure_reason: payment_intent.last_payment_error&.message || "Payment failed"
    )

    Notification.notify(
      transaction.sender,
      transaction,
      "payment_failed",
      "Payment failed: #{payment_intent.last_payment_error&.message}"
    )
  end

  def handle_charge_refunded(charge)
    transaction = Transaction.find_by(stripe_charge_id: charge.id)
    return unless transaction

    transaction.refund! unless transaction.status == "refunded"
  end

  def handle_dispute_created(dispute_obj)
    transaction = Transaction.find_by(stripe_charge_id: dispute_obj.charge)
    return unless transaction

    transaction.update!(status: "disputed", disputed_at: Time.current)
  end

  def handle_transfer_created(transfer)
    transaction = Transaction.find_by(stripe_transfer_id: transfer.id)
    return unless transaction

    transaction.release! unless transaction.status == "released"
  end

  def handle_account_updated(account)
    user = User.find_by(stripe_account_id: account.id)
    return unless user

    StripeConnectService.new(user).sync_account_status!
  end

  def handle_identity_verified(session)
    verification = IdentityVerification.find_by(stripe_verification_session_id: session.id)
    return unless verification

    KycVerificationService.new(verification.user).handle_verification_completed!(session)
  end

  def handle_identity_requires_input(session)
    verification = IdentityVerification.find_by(stripe_verification_session_id: session.id)
    return unless verification

    verification.update!(
      status: "rejected",
      rejection_reason: session.last_error&.reason || "Additional input required"
    )
  end
end

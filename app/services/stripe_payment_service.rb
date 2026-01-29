class StripePaymentService
  PLATFORM_FEE_RATE = 0.15
  MINIMUM_AMOUNT_CENTS = 1000 # 10€ minimum
  THREE_D_SECURE_THRESHOLD_CENTS = 3000 # 30€

  class PaymentError < StandardError; end
  class InsufficientFundsError < PaymentError; end
  class AccountNotReadyError < PaymentError; end

  def initialize(transaction)
    @transaction = transaction
    @sender = transaction.sender
    @traveler = transaction.traveler
  end

  # Create a Stripe PaymentIntent with escrow hold
  def create_payment_intent!
    validate_payment_prerequisites!

    ensure_customer_exists!(@sender)
    ensure_connect_account!(@traveler)

    idempotency_key = generate_idempotency_key("payment", @transaction.id)

    payment_intent = Stripe::PaymentIntent.create(
      {
        amount: @transaction.amount_cents.to_i,
        currency: @transaction.currency.downcase,
        customer: @sender.stripe_customer_id,
        payment_method_types: ['card'],
        capture_method: 'manual', # Hold funds, don't capture yet (escrow)
        transfer_data: {
          destination: @traveler.stripe_account_id
        },
        transfer_group: "shipping_request_#{@transaction.shipping_request_id}",
        application_fee_amount: @transaction.platform_fee_cents.to_i,
        metadata: {
          transaction_id: @transaction.id,
          shipping_request_id: @transaction.shipping_request_id,
          sender_id: @sender.id,
          traveler_id: @traveler.id
        },
        description: "ShareMyBag - Shipping Request ##{@transaction.shipping_request_id}"
      },
      { idempotency_key: idempotency_key }
    )

    @transaction.update!(
      stripe_payment_intent_id: payment_intent.id,
      idempotency_key: idempotency_key,
      three_d_secure: payment_intent.amount >= THREE_D_SECURE_THRESHOLD_CENTS,
      metadata: (@transaction.metadata || {}).merge(payment_intent_created_at: Time.current.iso8601)
    )

    log_audit("payment_intent_created", "success", payment_intent.id)

    payment_intent
  rescue Stripe::CardError => e
    log_audit("payment_intent_created", "failed", nil, error: e.message)
    @transaction.update!(failure_reason: e.message)
    raise PaymentError, e.message
  rescue Stripe::StripeError => e
    log_audit("payment_intent_created", "error", nil, error: e.message)
    raise PaymentError, "Payment processing error: #{e.message}"
  end

  # Create Stripe Checkout Session for the sender
  def create_checkout_session!(success_url:, cancel_url:)
    validate_payment_prerequisites!
    ensure_customer_exists!(@sender)
    ensure_connect_account!(@traveler)

    session = Stripe::Checkout::Session.create(
      mode: 'payment',
      customer: @sender.stripe_customer_id,
      line_items: [{
        price_data: {
          currency: @transaction.currency.downcase,
          product_data: {
            name: "Transport: #{@transaction.shipping_request.title}",
            description: "#{@transaction.shipping_request.departure_city} → #{@transaction.shipping_request.arrival_city}"
          },
          unit_amount: @transaction.amount_cents.to_i
        },
        quantity: 1
      }],
      payment_intent_data: {
        capture_method: 'manual',
        transfer_data: { destination: @traveler.stripe_account_id },
        application_fee_amount: @transaction.platform_fee_cents.to_i,
        transfer_group: "shipping_request_#{@transaction.shipping_request_id}",
        metadata: {
          transaction_id: @transaction.id,
          shipping_request_id: @transaction.shipping_request_id
        }
      },
      success_url: success_url,
      cancel_url: cancel_url,
      expires_after: 1800, # 30 minutes
      metadata: { transaction_id: @transaction.id }
    )

    @transaction.update!(
      metadata: (@transaction.metadata || {}).merge(
        checkout_session_id: session.id,
        checkout_created_at: Time.current.iso8601
      )
    )

    log_audit("checkout_session_created", "success", session.id)
    session
  rescue Stripe::StripeError => e
    log_audit("checkout_session_created", "error", nil, error: e.message)
    raise PaymentError, "Checkout error: #{e.message}"
  end

  # Capture held funds (move from hold to escrow)
  def capture_payment!
    return unless @transaction.stripe_payment_intent_id.present?

    payment_intent = Stripe::PaymentIntent.capture(
      @transaction.stripe_payment_intent_id,
      {},
      { idempotency_key: generate_idempotency_key("capture", @transaction.id) }
    )

    @transaction.pay!
    @transaction.update!(
      stripe_charge_id: payment_intent.latest_charge,
      metadata: (@transaction.metadata || {}).merge(captured_at: Time.current.iso8601)
    )

    log_audit("payment_captured", "success", payment_intent.id)
    payment_intent
  rescue Stripe::StripeError => e
    log_audit("payment_captured", "error", nil, error: e.message)
    raise PaymentError, "Capture error: #{e.message}"
  end

  # Release escrow funds to traveler after confirmed delivery
  def release_funds!
    raise PaymentError, "Transaction not in escrow" unless @transaction.status == "escrow"

    transfer = Stripe::Transfer.create(
      {
        amount: @transaction.traveler_payout_cents.to_i,
        currency: @transaction.currency.downcase,
        destination: @traveler.stripe_account_id,
        transfer_group: "shipping_request_#{@transaction.shipping_request_id}",
        metadata: {
          transaction_id: @transaction.id,
          shipping_request_id: @transaction.shipping_request_id
        }
      },
      { idempotency_key: generate_idempotency_key("release", @transaction.id) }
    )

    @transaction.release!
    @transaction.update!(
      stripe_transfer_id: transfer.id,
      escrow_released_at: Time.current,
      metadata: (@transaction.metadata || {}).merge(released_at: Time.current.iso8601)
    )

    log_audit("funds_released", "success", transfer.id)
    transfer
  rescue Stripe::StripeError => e
    log_audit("funds_released", "error", nil, error: e.message)
    raise PaymentError, "Release error: #{e.message}"
  end

  # Refund payment to sender
  def refund!(reason: "requested_by_customer", partial_amount_cents: nil)
    raise PaymentError, "No charge to refund" unless @transaction.stripe_charge_id.present?

    refund_params = {
      charge: @transaction.stripe_charge_id,
      reason: reason,
      metadata: {
        transaction_id: @transaction.id,
        refund_reason: reason
      }
    }
    refund_params[:amount] = partial_amount_cents.to_i if partial_amount_cents

    refund = Stripe::Refund.create(
      refund_params,
      { idempotency_key: generate_idempotency_key("refund", @transaction.id) }
    )

    @transaction.refund!
    @transaction.update!(
      stripe_refund_id: refund.id,
      metadata: (@transaction.metadata || {}).merge(refunded_at: Time.current.iso8601, refund_reason: reason)
    )

    log_audit("payment_refunded", "success", refund.id)
    refund
  rescue Stripe::StripeError => e
    log_audit("payment_refunded", "error", nil, error: e.message)
    raise PaymentError, "Refund error: #{e.message}"
  end

  private

  def validate_payment_prerequisites!
    raise PaymentError, "Amount below minimum (#{MINIMUM_AMOUNT_CENTS} cents)" if @transaction.amount_cents < MINIMUM_AMOUNT_CENTS
    raise AccountNotReadyError, "Traveler Stripe account not active" unless traveler_account_ready?
  end

  def traveler_account_ready?
    @traveler.stripe_account_id.present? &&
      @traveler.stripe_account_status.in?(%w[active])
  end

  def ensure_customer_exists!(user)
    return if user.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: user.email,
      name: user.name,
      metadata: { user_id: user.id }
    )
    user.update!(stripe_customer_id: customer.id)
  end

  def ensure_connect_account!(user)
    return if user.stripe_account_id.present?

    account = Stripe::Account.create(
      type: 'express',
      country: user.country.presence || 'FR',
      email: user.email,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true }
      },
      metadata: { user_id: user.id }
    )
    user.update!(stripe_account_id: account.id, stripe_account_status: "pending")
  end

  def generate_idempotency_key(action, transaction_id)
    "smb_#{action}_#{transaction_id}_#{SecureRandom.hex(8)}"
  end

  def log_audit(action, status, stripe_ref = nil, error: nil)
    PaymentAuditLog.create!(
      transaction: @transaction,
      user: @sender,
      action: action,
      status: status,
      amount_cents: @transaction.amount_cents,
      currency: @transaction.currency,
      stripe_event_id: stripe_ref,
      metadata: { error: error }.compact
    )
  rescue => e
    Rails.logger.error("Failed to create audit log: #{e.message}")
  end
end

class KycVerificationService
  KYC_VALIDITY_YEARS = 2
  MAX_ATTEMPTS = 3
  TRANSACTION_THRESHOLD_CENTS = 10000 # 100€
  MAX_TRANSACTIONS_WITHOUT_KYC = 3

  class VerificationError < StandardError; end

  def initialize(user)
    @user = user
  end

  # Check if KYC is required for a transaction
  def kyc_required?(amount_cents = 0)
    return false if @user.verified?
    amount_cents > TRANSACTION_THRESHOLD_CENTS ||
      @user.transactions_count.to_i >= MAX_TRANSACTIONS_WITHOUT_KYC
  end

  # Create Stripe Identity verification session
  def create_verification_session!(return_url:)
    verification = @user.identity_verification || @user.build_identity_verification(
      document_type: 'passport',
      status: 'pending'
    )

    if verification.attempts_count.to_i >= MAX_ATTEMPTS
      raise VerificationError, "Maximum verification attempts reached. Contact support."
    end

    session = Stripe::Identity::VerificationSession.create(
      type: 'document',
      metadata: {
        user_id: @user.id,
        verification_id: verification.id
      },
      options: {
        document: {
          allowed_types: ['driving_license', 'passport', 'id_card'],
          require_id_number: false,
          require_matching_selfie: true,
          require_live_capture: true
        }
      },
      return_url: return_url
    )

    verification.update!(
      stripe_verification_session_id: session.id,
      status: 'pending',
      attempts_count: verification.attempts_count.to_i + 1,
      last_attempt_at: Time.current
    )
    verification.save! if verification.new_record?

    session
  rescue Stripe::StripeError => e
    raise VerificationError, "Verification session error: #{e.message}"
  end

  # Handle completed verification from webhook
  def handle_verification_completed!(session)
    verification = @user.identity_verification
    return unless verification

    report = Stripe::Identity::VerificationReport.retrieve(session.last_verification_report)

    document = report.document
    selfie = report.selfie

    verification.update!(
      status: 'verified',
      verified_at: Time.current,
      verification_type: 'document',
      stripe_verification_report_id: report.id,
      liveness_check_passed: selfie&.status == 'verified',
      document_country: document&.issuing_country,
      document_expiry_date: parse_expiry(document&.expiration_date),
      first_name_match: document&.first_name.present?,
      last_name_match: document&.last_name.present?,
      expires_at: KYC_VALIDITY_YEARS.years.from_now,
      metadata: {
        document_type: document&.type,
        verified_via: 'stripe_identity',
        verified_at: Time.current.iso8601
      }
    )

    Notification.notify(
      @user, verification, "kyc_verified",
      "Your identity has been verified successfully!"
    )
  rescue Stripe::StripeError => e
    Rails.logger.error("KYC verification processing failed: #{e.message}")
  end

  # Check if verification has expired
  def verification_expired?
    verification = @user.identity_verification
    return true unless verification&.status == 'verified'
    return true if verification.expires_at.present? && verification.expires_at < Time.current
    false
  end

  # Get client secret for embedded verification
  def client_secret
    verification = @user.identity_verification
    return nil unless verification&.stripe_verification_session_id

    session = Stripe::Identity::VerificationSession.retrieve(
      verification.stripe_verification_session_id
    )
    session.client_secret
  rescue Stripe::StripeError
    nil
  end

  private

  def parse_expiry(date_hash)
    return nil unless date_hash
    Date.new(date_hash['year'], date_hash['month'], date_hash['day']) rescue nil
  end
end

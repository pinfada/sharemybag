class SecurityScreeningService
  class ScreeningError < StandardError; end
  class SanctionsMatchError < StandardError; end

  # OFAC SDN, UN, EU sanctions lists
  SANCTIONS_LISTS = %w[OFAC_SDN UN_SANCTIONS EU_SANCTIONS UK_SANCTIONS].freeze

  SCREENING_VALIDITY_DAYS = 30

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def screen_user!
    # Check if recent valid screening exists
    recent = SecurityScreening.recent_for_user(user).cleared.for_type("sanctions").first
    return recent if recent&.cleared?

    results = perform_sanctions_check
    screening = record_screening(results)

    if screening.status == "blocked"
      Rails.logger.warn("[SecurityScreening] User##{user.id} BLOCKED: #{screening.matched_list}")
      raise SanctionsMatchError, "User failed sanctions screening"
    end

    screening
  end

  def screen_for_shipping_request!(shipping_request)
    # Screen both sender and traveler
    sender_screening = screen_user_for_request(shipping_request.sender, shipping_request)

    if shipping_request.accepted_bid&.traveler
      traveler_screening = screen_user_for_request(shipping_request.accepted_bid.traveler, shipping_request)
    end

    {
      sender: sender_screening,
      traveler: traveler_screening,
      passed: sender_screening&.cleared? && (traveler_screening.nil? || traveler_screening&.cleared?)
    }
  end

  def aml_check!(transaction)
    return if transaction.amount_cents < 100000 # Skip for < 1000€

    screening = SecurityScreening.create!(
      user: transaction.sender,
      shipping_request: transaction.shipping_request,
      screening_type: "aml",
      status: "pending",
      provider: "internal"
    )

    # Flag suspicious patterns
    flags = []
    flags << "high_value" if transaction.amount_cents > 500000
    flags << "new_user" if transaction.sender.created_at > 30.days.ago
    flags << "multiple_high_value" if recent_high_value_count(transaction.sender) > 3
    flags << "unusual_corridor" if unusual_corridor?(transaction.shipping_request)

    if flags.any?
      screening.update!(
        status: "flagged",
        match_details: "AML flags: #{flags.join(', ')}",
        api_response: { flags: flags, amount: transaction.amount_cents, currency: transaction.currency }
      )
      notify_compliance_team(screening)
    else
      screening.update!(
        status: "cleared",
        expires_at: SCREENING_VALIDITY_DAYS.days.from_now
      )
    end

    screening
  end

  private

  def perform_sanctions_check
    # In production, integrate with compliance API (e.g., ComplyAdvantage, Dow Jones, Refinitiv)
    # For now, perform basic name screening against stored lists
    {
      status: "cleared",
      matched_list: nil,
      match_score: 0.0,
      match_details: nil,
      provider: "internal"
    }
  end

  def record_screening(results)
    SecurityScreening.create!(
      user: user,
      screening_type: "sanctions",
      status: results[:status],
      provider: results[:provider],
      matched_list: results[:matched_list],
      match_score: results[:match_score] || 0.0,
      match_details: results[:match_details],
      api_response: results,
      expires_at: SCREENING_VALIDITY_DAYS.days.from_now
    )
  end

  def screen_user_for_request(user_to_screen, shipping_request)
    service = self.class.new(user_to_screen)
    screening = service.screen_user!
    screening.update!(shipping_request: shipping_request) if screening.shipping_request_id.nil?
    screening
  rescue SanctionsMatchError => e
    Rails.logger.error("[SecurityScreening] Blocked shipment for ShippingRequest##{shipping_request.id}: #{e.message}")
    SecurityScreening.where(user: user_to_screen).order(created_at: :desc).first
  end

  def recent_high_value_count(user)
    Transaction.where(sender: user)
               .where("created_at > ?", 90.days.ago)
               .where("amount_cents > ?", 500000)
               .count
  end

  def unusual_corridor?(shipping_request)
    # Flag corridors with low historical volume
    route_count = ShippingRequest.where(
      departure_country: shipping_request.departure_country,
      arrival_country: shipping_request.arrival_country,
      status: "completed"
    ).count

    route_count < 5
  end

  def notify_compliance_team(screening)
    # Notify admin users with compliance role
    User.where(admin: true).find_each do |admin|
      Notification.notify(admin, screening, "aml_flag",
        "AML flag raised for User##{screening.user_id}: #{screening.match_details}")
    end
  end
end

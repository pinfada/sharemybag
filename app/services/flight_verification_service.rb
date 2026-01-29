class FlightVerificationService
  MAX_DAILY_ATTEMPTS = 10
  CACHE_TTL = 24.hours
  NAME_MATCH_THRESHOLD = 0.85
  MIN_DAYS_AHEAD = 2
  MAX_MONTHS_AHEAD = 6

  class VerificationError < StandardError; end
  class FlightNotFoundError < VerificationError; end
  class RateLimitExceededError < VerificationError; end
  class FraudDetectedError < VerificationError; end

  def initialize(kilo_offer, user = nil)
    @kilo_offer = kilo_offer
    @user = user || kilo_offer.traveler
  end

  # Verify a flight number via Amadeus API
  def verify_flight!(flight_number)
    check_rate_limit!
    validate_flight_number_format!(flight_number)

    verification = find_or_create_verification(flight_number)

    cached = check_cache(flight_number, @kilo_offer.travel_date)
    if cached
      apply_cached_result(verification, cached)
      return verification
    end

    flight_data = fetch_flight_from_amadeus(flight_number, @kilo_offer.travel_date)

    if flight_data
      process_flight_data(verification, flight_data)
    else
      verification.update!(
        status: 'rejected',
        rejection_reason: 'Flight not found in airline database',
        verification_source: 'amadeus'
      )
    end

    cache_result(flight_number, @kilo_offer.travel_date, verification)
    check_fraud_patterns(verification)

    verification
  rescue Faraday::Error, Net::OpenTimeout => e
    fallback_verification(verification || find_or_create_verification(flight_number), flight_number, e)
  end

  # Verify uploaded ticket via OCR (simplified - would use external OCR service)
  def verify_ticket!(ticket_url)
    verification = @kilo_offer.flight_verification || FlightVerification.new(
      kilo_offer: @kilo_offer,
      user: @user
    )

    verification.update!(
      ticket_url: ticket_url,
      status: 'manual_review',
      verification_source: 'ticket_upload'
    )

    verification
  end

  private

  def check_rate_limit!
    today_count = FlightVerification.where(user: @user)
                                     .where("created_at >= ?", Time.current.beginning_of_day)
                                     .count
    if today_count >= MAX_DAILY_ATTEMPTS
      raise RateLimitExceededError, "Maximum #{MAX_DAILY_ATTEMPTS} verifications per day"
    end
  end

  def validate_flight_number_format!(flight_number)
    unless flight_number.match?(/\A[A-Z]{2}\d{1,4}\z/i)
      raise VerificationError, "Invalid flight number format. Expected: XX1234"
    end
  end

  def find_or_create_verification(flight_number)
    @kilo_offer.flight_verification || FlightVerification.create!(
      kilo_offer: @kilo_offer,
      user: @user,
      flight_number: flight_number.upcase,
      departure_airport: @kilo_offer.departure_city,
      arrival_airport: @kilo_offer.arrival_city,
      departure_date: @kilo_offer.travel_date,
      status: 'pending'
    )
  end

  def fetch_flight_from_amadeus(flight_number, date)
    token = amadeus_auth_token
    return nil unless token

    airline_code = flight_number[0..1].upcase
    flight_num = flight_number[2..].to_i

    response = amadeus_client.get("/v2/schedule/flights") do |req|
      req.params['carrierCode'] = airline_code
      req.params['flightNumber'] = flight_num
      req.params['scheduledDepartureDate'] = date.to_s
    end

    return nil unless response.status == 200

    data = JSON.parse(response.body)
    data['data']&.first
  rescue => e
    Rails.logger.error("Amadeus API error: #{e.message}")
    nil
  end

  def process_flight_data(verification, flight_data)
    departure = flight_data.dig('flightPoints', 0)
    arrival = flight_data.dig('flightPoints', 1)

    departure_matches = airport_matches?(departure&.dig('iataCode'), @kilo_offer.departure_city)
    arrival_matches = airport_matches?(arrival&.dig('iataCode'), @kilo_offer.arrival_city)

    status = if departure_matches && arrival_matches
               'verified'
             else
               'rejected'
             end

    rejection_reason = unless departure_matches && arrival_matches
                         "Route mismatch: expected #{@kilo_offer.departure_city}→#{@kilo_offer.arrival_city}"
                       end

    verification.update!(
      status: status,
      verification_source: 'amadeus',
      airline_code: flight_data.dig('flightDesignator', 'carrierCode'),
      departure_airport: departure&.dig('iataCode'),
      arrival_airport: arrival&.dig('iataCode'),
      departure_time: parse_time(departure&.dig('departure', 'timings', 0, 'value')),
      arrival_time: parse_time(arrival&.dig('arrival', 'timings', 0, 'value')),
      api_response: flight_data,
      verified_at: status == 'verified' ? Time.current : nil,
      rejection_reason: rejection_reason
    )
  end

  def airport_matches?(iata_code, city_name)
    return false unless iata_code && city_name
    iata_code.downcase.include?(city_name[0..2].downcase) ||
      city_name.downcase.include?(iata_code.downcase)
  end

  def check_fraud_patterns(verification)
    flags = []

    # Check for multiple rejected verifications
    rejected_count = FlightVerification.where(user: @user, status: 'rejected').count
    flags << "multiple_rejections" if rejected_count >= 3

    # Check if same flight used by multiple users
    same_flight = FlightVerification.where(flight_number: verification.flight_number, departure_date: verification.departure_date)
                                     .where.not(user: @user)
                                     .where(status: 'verified')
                                     .exists?
    flags << "duplicate_flight" if same_flight

    verification.update!(fraud_flags: flags) if flags.any?

    if flags.include?("multiple_rejections") && rejected_count >= 3
      Notification.notify(
        User.find_by(admin: true) || @user,
        verification,
        "fraud_alert",
        "Fraud alert: User #{@user.name} has #{rejected_count} rejected flight verifications"
      )
    end
  end

  def fallback_verification(verification, flight_number, original_error)
    Rails.logger.warn("Amadeus unavailable, marking for manual review: #{original_error.message}")
    verification.update!(
      status: 'manual_review',
      verification_source: 'manual',
      rejection_reason: "API unavailable: #{original_error.message}"
    )
    verification
  end

  def check_cache(flight_number, date)
    Rails.cache.read("flight_#{flight_number}_#{date}")
  end

  def cache_result(flight_number, date, verification)
    Rails.cache.write(
      "flight_#{flight_number}_#{date}",
      { status: verification.status, api_response: verification.api_response },
      expires_in: CACHE_TTL
    )
  end

  def apply_cached_result(verification, cached)
    verification.update!(
      status: cached[:status],
      api_response: cached[:api_response],
      verification_source: 'cache',
      verified_at: cached[:status] == 'verified' ? Time.current : nil
    )
  end

  def amadeus_client
    @amadeus_client ||= Faraday.new(url: 'https://api.amadeus.com') do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.headers['Authorization'] = "Bearer #{amadeus_auth_token}"
      f.options.timeout = 10
      f.options.open_timeout = 5
    end
  end

  def amadeus_auth_token
    cached_token = Rails.cache.read('amadeus_auth_token')
    return cached_token if cached_token

    response = Faraday.post('https://api.amadeus.com/v1/security/oauth2/token') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        grant_type: 'client_credentials',
        client_id: ENV['AMADEUS_API_KEY'],
        client_secret: ENV['AMADEUS_API_SECRET']
      )
    end

    if response.status == 200
      data = JSON.parse(response.body)
      token = data['access_token']
      Rails.cache.write('amadeus_auth_token', token, expires_in: (data['expires_in'] || 1799).seconds)
      token
    end
  rescue => e
    Rails.logger.error("Amadeus auth failed: #{e.message}")
    nil
  end

  def parse_time(time_str)
    Time.parse(time_str) rescue nil
  end
end

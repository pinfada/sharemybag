class OtpService
  OTP_LENGTH = 6
  OTP_VALIDITY_MINUTES = 30
  MAX_ATTEMPTS = 3
  RATE_LIMIT_SECONDS = 60
  MAX_DAILY_BLOCKS = 10

  class OtpError < StandardError; end
  class OtpExpiredError < OtpError; end
  class OtpBlockedError < OtpError; end
  class RateLimitError < OtpError; end

  def initialize(shipment_tracking)
    @tracking = shipment_tracking
    @shipping_request = shipment_tracking.shipping_request
  end

  # Generate and send OTP to the recipient (sender of the package)
  def generate_and_send!
    check_rate_limit!

    otp_code = generate_otp
    confirmation = find_or_create_confirmation(otp_code)

    raise OtpBlockedError, "Too many failed attempts. Contact support." if confirmation.blocked?

    # Send via SMS first, fallback to email
    sent = send_otp_sms(otp_code, @shipping_request.sender)
    unless sent
      send_otp_email(otp_code, @shipping_request.sender)
      confirmation.update!(notification_channel: 'email', email_sent: true, email_sent_at: Time.current)
    end

    @tracking.update!(otp_required: true)

    {
      confirmation_id: confirmation.id,
      channel: confirmation.notification_channel,
      expires_at: confirmation.otp_expires_at
    }
  end

  # Verify OTP code entered by traveler
  def verify!(code, photo_url: nil, latitude: nil, longitude: nil, ip_address: nil)
    confirmation = @tracking.delivery_confirmation
    raise OtpError, "No OTP generated for this delivery" unless confirmation
    raise OtpBlockedError, "Verification blocked. Contact support." if confirmation.blocked?
    raise OtpExpiredError, "OTP has expired. Request a new code." if otp_expired?(confirmation)

    if verify_code(code, confirmation.otp_digest)
      confirm_delivery!(confirmation, photo_url: photo_url, latitude: latitude,
                        longitude: longitude, ip_address: ip_address)
      { success: true, message: "Delivery confirmed successfully" }
    else
      handle_failed_attempt!(confirmation)
    end
  end

  # Resend OTP (regenerate)
  def resend!
    confirmation = @tracking.delivery_confirmation
    if confirmation
      check_rate_limit!
      otp_code = generate_otp
      confirmation.update!(
        otp_digest: BCrypt::Password.create(otp_code),
        otp_generated_at: Time.current,
        otp_expires_at: OTP_VALIDITY_MINUTES.minutes.from_now,
        attempts_count: 0,
        blocked: false,
        blocked_at: nil
      )
      send_otp_sms(otp_code, @shipping_request.sender)
      { success: true, expires_at: confirmation.otp_expires_at }
    else
      generate_and_send!
    end
  end

  private

  def generate_otp
    SecureRandom.random_number(10**OTP_LENGTH).to_s.rjust(OTP_LENGTH, '0')
  end

  def find_or_create_confirmation(otp_code)
    confirmation = @tracking.delivery_confirmation

    if confirmation
      confirmation.update!(
        otp_digest: BCrypt::Password.create(otp_code),
        otp_generated_at: Time.current,
        otp_expires_at: OTP_VALIDITY_MINUTES.minutes.from_now,
        attempts_count: 0,
        blocked: false
      )
      confirmation
    else
      DeliveryConfirmation.create!(
        shipment_tracking: @tracking,
        sender: @shipping_request.sender,
        traveler: @tracking.traveler,
        otp_digest: BCrypt::Password.create(otp_code),
        otp_generated_at: Time.current,
        otp_expires_at: OTP_VALIDITY_MINUTES.minutes.from_now,
        notification_channel: 'sms'
      )
    end
  end

  def verify_code(code, digest)
    BCrypt::Password.new(digest) == code
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def otp_expired?(confirmation)
    confirmation.otp_expires_at < Time.current
  end

  def confirm_delivery!(confirmation, photo_url: nil, latitude: nil, longitude: nil, ip_address: nil)
    ActiveRecord::Base.transaction do
      confirmation.update!(
        otp_verified_at: Time.current,
        delivery_photo_url: photo_url,
        delivery_latitude: latitude,
        delivery_longitude: longitude,
        confirmed_by_ip: ip_address
      )

      @tracking.deliver!
      @tracking.update!(delivery_confirmed_via_otp: true)

      # Notify sender that delivery is confirmed
      Notification.notify(
        @shipping_request.sender,
        @tracking,
        "delivery_otp_confirmed",
        "Your package has been delivered and confirmed via OTP"
      )

      # Notify traveler
      Notification.notify(
        @tracking.traveler,
        @tracking,
        "delivery_confirmed",
        "Delivery confirmed! Funds will be released shortly."
      )
    end
  end

  def handle_failed_attempt!(confirmation)
    confirmation.increment!(:attempts_count)

    remaining = MAX_ATTEMPTS - confirmation.attempts_count

    if remaining <= 0
      confirmation.update!(blocked: true, blocked_at: Time.current)
      Notification.notify(
        @shipping_request.sender,
        @tracking,
        "otp_blocked",
        "OTP verification blocked after #{MAX_ATTEMPTS} failed attempts"
      )
      raise OtpBlockedError, "Maximum attempts reached. Verification blocked."
    end

    { success: false, remaining_attempts: remaining, message: "Invalid code. #{remaining} attempts remaining." }
  end

  def check_rate_limit!
    confirmation = @tracking.delivery_confirmation
    return unless confirmation

    if confirmation.otp_generated_at && confirmation.otp_generated_at > RATE_LIMIT_SECONDS.seconds.ago
      raise RateLimitError, "Please wait before requesting a new code"
    end
  end

  def send_otp_sms(code, recipient)
    return false unless recipient.phone.present?

    begin
      client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
      message = client.messages.create(
        from: ENV['TWILIO_PHONE_NUMBER'],
        to: recipient.phone,
        body: "ShareMyBag - Your delivery confirmation code is: #{code}. Valid for #{OTP_VALIDITY_MINUTES} minutes. Do not share this code."
      )

      confirmation = @tracking.delivery_confirmation
      confirmation&.update!(
        sms_sent: true,
        sms_sent_at: Time.current,
        sms_provider: 'twilio',
        sms_message_sid: message.sid,
        notification_channel: 'sms'
      )

      true
    rescue Twilio::REST::RestError => e
      Rails.logger.error("Twilio SMS error: #{e.message}")
      false
    rescue => e
      Rails.logger.error("SMS sending error: #{e.message}")
      false
    end
  end

  def send_otp_email(code, recipient)
    OtpMailer.delivery_code(recipient, code, OTP_VALIDITY_MINUTES).deliver_later
    true
  rescue => e
    Rails.logger.error("OTP email error: #{e.message}")
    false
  end
end

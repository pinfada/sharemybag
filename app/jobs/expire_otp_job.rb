class ExpireOtpJob < ApplicationJob
  queue_as :default

  def perform(delivery_confirmation_id)
    confirmation = DeliveryConfirmation.find_by(id: delivery_confirmation_id)
    return unless confirmation
    return if confirmation.otp_verified_at.present?

    if confirmation.otp_expires_at <= Time.current
      Rails.logger.info("[ExpireOtpJob] OTP expired for DeliveryConfirmation##{delivery_confirmation_id}")
    end
  end
end

class VerifyFlightJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(kilo_offer_id)
    kilo_offer = KiloOffer.find(kilo_offer_id)
    return unless kilo_offer.flight_number.present?

    service = FlightVerificationService.new(kilo_offer)
    service.verify_flight!(kilo_offer.flight_number)
  rescue FlightVerificationService::RateLimitExceededError
    retry_job(wait: 1.hour)
  rescue FlightVerificationService::VerificationError => e
    Rails.logger.error("[VerifyFlightJob] Verification failed for KiloOffer##{kilo_offer_id}: #{e.message}")
  end
end

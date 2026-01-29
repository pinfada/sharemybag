class FlightVerificationsController < ApplicationController
  before_action :signed_in_user
  before_action :set_kilo_offer

  # POST /kilo_offers/:kilo_offer_id/flight_verification
  def create
    authorize_traveler!

    service = FlightVerificationService.new(@kilo_offer, current_user)

    begin
      if params[:flight_number].present?
        @verification = service.verify_flight!(params[:flight_number])
      elsif params[:ticket_url].present?
        @verification = service.verify_ticket!(params[:ticket_url])
      else
        flash[:error] = I18n.t('flight_verifications.missing_info')
        redirect_to @kilo_offer and return
      end

      case @verification.status
      when 'verified'
        flash[:success] = I18n.t('flight_verifications.verified')
      when 'rejected'
        flash[:error] = I18n.t('flight_verifications.rejected', reason: @verification.rejection_reason)
      when 'manual_review'
        flash[:notice] = I18n.t('flight_verifications.manual_review')
      end

      redirect_to @kilo_offer
    rescue FlightVerificationService::RateLimitExceededError => e
      flash[:error] = e.message
      redirect_to @kilo_offer
    rescue FlightVerificationService::VerificationError => e
      flash[:error] = e.message
      redirect_to @kilo_offer
    end
  end

  # GET /kilo_offers/:kilo_offer_id/flight_verification
  def show
    @verification = @kilo_offer.flight_verification
    redirect_to @kilo_offer unless @verification
  end

  private

  def set_kilo_offer
    @kilo_offer = KiloOffer.find(params[:kilo_offer_id])
  end

  def authorize_traveler!
    unless current_user.id == @kilo_offer.traveler_id
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end
end

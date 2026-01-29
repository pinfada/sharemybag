class DeliveryConfirmationsController < ApplicationController
  before_action :signed_in_user
  before_action :set_tracking
  before_action :authorize_participant

  # POST /shipment_trackings/:shipment_tracking_id/delivery_confirmation/generate
  def generate
    authorize_traveler!

    service = OtpService.new(@tracking)

    begin
      result = service.generate_and_send!
      flash[:success] = I18n.t('delivery_confirmations.otp_sent', channel: result[:channel])
    rescue OtpService::OtpBlockedError => e
      flash[:error] = e.message
    rescue OtpService::RateLimitError => e
      flash[:error] = e.message
    rescue OtpService::OtpError => e
      flash[:error] = e.message
    end

    redirect_to shipment_tracking_path(@tracking)
  end

  # POST /shipment_trackings/:shipment_tracking_id/delivery_confirmation/verify
  def verify
    authorize_traveler!

    service = OtpService.new(@tracking)

    begin
      result = service.verify!(
        params[:otp_code],
        photo_url: params[:delivery_photo_url],
        latitude: params[:latitude],
        longitude: params[:longitude],
        ip_address: request.remote_ip
      )

      if result[:success]
        flash[:success] = I18n.t('delivery_confirmations.confirmed')
      else
        flash[:error] = result[:message]
      end
    rescue OtpService::OtpExpiredError => e
      flash[:error] = e.message
    rescue OtpService::OtpBlockedError => e
      flash[:error] = e.message
    rescue OtpService::OtpError => e
      flash[:error] = e.message
    end

    redirect_to shipment_tracking_path(@tracking)
  end

  # POST /shipment_trackings/:shipment_tracking_id/delivery_confirmation/resend
  def resend
    authorize_traveler!

    service = OtpService.new(@tracking)

    begin
      result = service.resend!
      flash[:success] = I18n.t('delivery_confirmations.otp_resent')
    rescue OtpService::RateLimitError => e
      flash[:error] = e.message
    rescue OtpService::OtpError => e
      flash[:error] = e.message
    end

    redirect_to shipment_tracking_path(@tracking)
  end

  private

  def set_tracking
    @tracking = ShipmentTracking.find(params[:shipment_tracking_id])
  end

  def authorize_participant
    sender_id = @tracking.shipping_request.sender_id
    traveler_id = @tracking.traveler_id
    unless current_user.id.in?([sender_id, traveler_id])
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end

  def authorize_traveler!
    unless current_user.id == @tracking.traveler_id
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end
end

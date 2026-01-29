class HandlingEventsController < ApplicationController
  before_action :signed_in_user
  before_action :set_tracking
  before_action :authorize_participant

  def index
    @events = @tracking.handling_events.chronological
    @chain_verification = HandlingEvent.verify_chain(@tracking)
  end

  def create
    event = @tracking.handling_events.build(handling_event_params)
    event.actor = current_user

    if event.save
      flash[:success] = I18n.t('handling_events.created', default: "Handling event recorded.")
      redirect_to shipment_tracking_path(@tracking)
    else
      flash[:error] = event.errors.full_messages.join(", ")
      redirect_to shipment_tracking_path(@tracking)
    end
  end

  private

  def set_tracking
    @tracking = ShipmentTracking.find(params[:shipment_tracking_id])
  end

  def authorize_participant
    sender_id = @tracking.shipping_request.sender_id
    traveler_id = @tracking.traveler_id
    unless current_user.id == sender_id || current_user.id == traveler_id || current_user.admin?
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end

  def handling_event_params
    params.require(:handling_event).permit(
      :event_type, :location, :latitude, :longitude, :photo_url,
      :notes, :barcode_scanned, :seal_number, :seal_intact
    )
  end
end

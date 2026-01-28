class ShipmentTrackingsController < ApplicationController
  before_action :signed_in_user
  before_action :set_tracking

  def show
    @timeline = @tracking.status_timeline
  end

  def hand_over
    if params[:code] == @tracking.handover_code
      @tracking.hand_over!
      Notification.notify(@tracking.shipping_request.sender, @tracking, "handed_over",
        I18n.t('notifications.package_handed_over'))
      flash[:success] = I18n.t('tracking.handed_over')
    else
      flash[:error] = I18n.t('tracking.invalid_code')
    end
    redirect_to shipment_tracking_path(@tracking)
  end

  def mark_in_transit
    @tracking.mark_in_transit!
    Notification.notify(@tracking.shipping_request.sender, @tracking, "in_transit",
      I18n.t('notifications.package_in_transit'))
    flash[:success] = I18n.t('tracking.in_transit')
    redirect_to shipment_tracking_path(@tracking)
  end

  def deliver
    if params[:code] == @tracking.delivery_code
      @tracking.deliver!
      Notification.notify(@tracking.shipping_request.sender, @tracking, "delivered",
        I18n.t('notifications.package_delivered'))
      flash[:success] = I18n.t('tracking.delivered')
    else
      flash[:error] = I18n.t('tracking.invalid_code')
    end
    redirect_to shipment_tracking_path(@tracking)
  end

  def confirm
    @tracking.confirm!
    transaction = @tracking.shipping_request.transaction
    transaction&.release!

    @tracking.shipping_request.update!(status: "completed")

    Notification.notify(@tracking.traveler, @tracking, "confirmed",
      I18n.t('notifications.delivery_confirmed'))
    flash[:success] = I18n.t('tracking.confirmed')
    redirect_to shipment_tracking_path(@tracking)
  end

  private

  def set_tracking
    @tracking = ShipmentTracking.find(params[:id])
  end
end

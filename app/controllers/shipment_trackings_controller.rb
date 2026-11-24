class ShipmentTrackingsController < ApplicationController
  before_action :signed_in_user
  before_action :set_tracking
  before_action :authorize_participant
  before_action :authorize_traveler, only: [:hand_over, :mark_in_transit, :deliver]
  before_action :authorize_sender, only: [:confirm]

  def show
    @shipping_request = @tracking.shipping_request
    @accepted_bid = @shipping_request.accepted_bid
    @timeline = @tracking.status_timeline
    @is_sender = @tracking.sender?(current_user)
    @is_traveler = @tracking.traveler?(current_user)
    @already_reviewed = @shipping_request.reviews.exists?(reviewer_id: current_user.id)
    @review = Review.new
  end

  def hand_over
    inspected = ActiveModel::Type::Boolean.new.cast(params[:open_inspection_confirmed])
    unless inspected
      flash[:error] = t('tracking.open_inspection_required')
      redirect_to shipment_tracking_path(@tracking) and return
    end

    if @tracking.verify_and_hand_over!(params[:code], open_inspection_confirmed: true)
      Notification.notify(
        @tracking.shipping_request.sender,
        @tracking,
        "handed_over",
        t('notifications.package_handed_over')
      )
      flash[:success] = t('tracking.handed_over')
    else
      flash[:error] = t('tracking.invalid_code')
    end
    redirect_to shipment_tracking_path(@tracking)
  rescue ShipmentTracking::InvalidTransitionError => e
    flash[:error] = e.message
    redirect_to shipment_tracking_path(@tracking)
  end

  def mark_in_transit
    @tracking.mark_in_transit!
    Notification.notify(
      @tracking.shipping_request.sender,
      @tracking,
      "in_transit",
      t('notifications.package_in_transit')
    )
    flash[:success] = t('tracking.in_transit')
    redirect_to shipment_tracking_path(@tracking)
  rescue ShipmentTracking::InvalidTransitionError => e
    flash[:error] = e.message
    redirect_to shipment_tracking_path(@tracking)
  end

  def deliver
    if @tracking.verify_and_deliver!(params[:code])
      Notification.notify(
        @tracking.shipping_request.sender,
        @tracking,
        "delivered",
        t('notifications.package_delivered')
      )
      flash[:success] = t('tracking.delivered')
    else
      flash[:error] = t('tracking.invalid_code')
    end
    redirect_to shipment_tracking_path(@tracking)
  rescue ShipmentTracking::InvalidTransitionError => e
    flash[:error] = e.message
    redirect_to shipment_tracking_path(@tracking)
  end

  def confirm
    @tracking.confirm!
    Notification.notify(
      @tracking.traveler,
      @tracking,
      "confirmed",
      t('notifications.delivery_confirmed')
    )
    flash[:success] = t('tracking.confirmed')
    redirect_to shipment_tracking_path(@tracking)
  rescue ShipmentTracking::InvalidTransitionError => e
    flash[:error] = e.message
    redirect_to shipment_tracking_path(@tracking)
  end

  private

  def set_tracking
    @tracking = ShipmentTracking.includes(shipping_request: :sender).find(params[:id])
  end

  def authorize_participant
    return if @tracking.participant?(current_user)

    flash[:error] = t('common.unauthorized')
    redirect_to root_url
  end

  def authorize_traveler
    return if @tracking.traveler?(current_user)

    flash[:error] = t('common.unauthorized')
    redirect_to root_url
  end

  def authorize_sender
    return if @tracking.sender?(current_user)

    flash[:error] = t('common.unauthorized')
    redirect_to root_url
  end
end

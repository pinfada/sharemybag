class BidsController < ApplicationController
  before_action :signed_in_user
  before_action :set_shipping_request, only: [:create]

  def create
    @bid = @shipping_request.bids.build(bid_params)
    @bid.traveler = current_user
    @bid.currency = @shipping_request.currency

    if @bid.save
      @shipping_request.update!(status: "bidding") if @shipping_request.status == "open"

      Notification.notify(
        @shipping_request.sender,
        @shipping_request,
        "new_bid",
        t('notifications.new_bid', name: current_user.name, title: @shipping_request.title)
      )

      flash[:success] = t('bids.created')
    else
      flash[:error] = @bid.errors.full_messages.join(" · ")
    end

    redirect_to @shipping_request
  end

  def withdraw
    @bid = current_user.bids.find(params[:id])
    @bid.withdraw!
    flash[:success] = t('bids.withdrawn')
    redirect_to @bid.shipping_request
  rescue Bid::InvalidTransitionError => e
    flash[:error] = e.message
    redirect_to @bid.shipping_request
  end

  def my_bids
    @bids = current_user.bids
                        .includes(shipping_request: [:sender, :shipment_tracking])
                        .order(created_at: :desc)
                        .paginate(page: params[:page], per_page: 12)
  end

  private

  def set_shipping_request
    @shipping_request = ShippingRequest.find(params[:shipping_request_id])
  end

  def bid_params
    params.require(:bid).permit(
      :price_per_kg_euros, :price_per_kg_cents,
      :available_kg, :travel_date, :flight_number, :message
    )
  end
end

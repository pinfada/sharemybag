class BidsController < ApplicationController
  before_action :signed_in_user
  before_action :set_shipping_request, only: [:create]

  def create
    @bid = @shipping_request.bids.build(bid_params)
    @bid.traveler = current_user
    if @bid.save
      @shipping_request.update(status: "bidding") if @shipping_request.status == "open"

      Notification.notify(@shipping_request.sender, @shipping_request, "new_bid",
        I18n.t('notifications.new_bid', name: current_user.name, title: @shipping_request.title))

      flash[:success] = I18n.t('bids.created')
      redirect_to @shipping_request
    else
      flash[:error] = @bid.errors.full_messages.join(", ")
      redirect_to @shipping_request
    end
  end

  def withdraw
    @bid = current_user.bids.find(params[:id])
    @bid.update(status: "withdrawn")
    flash[:success] = I18n.t('bids.withdrawn')
    redirect_to @bid.shipping_request
  end

  def my_bids
    @bids = current_user.bids
                        .includes(:shipping_request)
                        .order(created_at: :desc)
                        .paginate(page: params[:page], per_page: 20)
  end

  private

  def set_shipping_request
    @shipping_request = ShippingRequest.find(params[:shipping_request_id])
  end

  def bid_params
    params.require(:bid).permit(
      :price_per_kg_cents, :available_kg, :currency,
      :travel_date, :flight_number, :message, :kilo_offer_id
    )
  end
end

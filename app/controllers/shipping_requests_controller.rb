class ShippingRequestsController < ApplicationController
  before_action :signed_in_user
  before_action :set_shipping_request, only: [:show, :edit, :update, :destroy, :accept_bid]
  before_action :correct_sender, only: [:edit, :update, :destroy, :accept_bid]

  def index
    @shipping_requests = ShippingRequest.active
                                        .includes(:sender)
                                        .order(created_at: :desc)
                                        .paginate(page: params[:page], per_page: 20)

    if params[:departure_city].present?
      @shipping_requests = @shipping_requests.where("LOWER(departure_city) LIKE ?", "%#{params[:departure_city].downcase}%")
    end
    if params[:arrival_city].present?
      @shipping_requests = @shipping_requests.where("LOWER(arrival_city) LIKE ?", "%#{params[:arrival_city].downcase}%")
    end
    if params[:max_weight].present?
      @shipping_requests = @shipping_requests.by_max_weight(params[:max_weight])
    end
    if params[:date_from].present?
      @shipping_requests = @shipping_requests.by_date(params[:date_from])
    end
  end

  def show
    @bids = @shipping_request.bids.includes(:traveler).order(price_per_kg_cents: :asc)
    @bid = Bid.new
    @tracking = @shipping_request.shipment_tracking
  end

  def new
    @shipping_request = current_user.shipping_requests.build
  end

  def create
    @shipping_request = current_user.shipping_requests.build(shipping_request_params)
    if @shipping_request.save
      flash[:success] = I18n.t('shipping_requests.created')
      redirect_to @shipping_request
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @shipping_request.update(shipping_request_params)
      flash[:success] = I18n.t('shipping_requests.updated')
      redirect_to @shipping_request
    else
      render :edit
    end
  end

  def destroy
    @shipping_request.update(status: "cancelled")
    flash[:success] = I18n.t('shipping_requests.cancelled')
    redirect_to shipping_requests_path
  end

  def accept_bid
    bid = @shipping_request.bids.find(params[:bid_id])
    @shipping_request.accept_bid!(bid)

    transaction = Transaction.create_from_bid(bid)
    ShipmentTracking.create!(
      shipping_request: @shipping_request,
      traveler: bid.traveler
    )

    Notification.notify(bid.traveler, @shipping_request, "bid_accepted",
      I18n.t('notifications.bid_accepted', title: @shipping_request.title))

    flash[:success] = I18n.t('shipping_requests.bid_accepted')
    redirect_to @shipping_request
  end

  def my_requests
    @shipping_requests = current_user.shipping_requests
                                     .order(created_at: :desc)
                                     .paginate(page: params[:page], per_page: 20)
  end

  private

  def set_shipping_request
    @shipping_request = ShippingRequest.find(params[:id])
  end

  def correct_sender
    redirect_to root_url unless @shipping_request.sender_id == current_user.id
  end

  def shipping_request_params
    params.require(:shipping_request).permit(
      :title, :description, :weight_kg, :length_cm, :width_cm, :height_cm,
      :departure_city, :departure_country, :arrival_city, :arrival_country,
      :desired_date, :deadline_date, :max_budget_cents, :currency,
      :item_category, :special_instructions
    )
  end
end

class ShippingRequestsController < ApplicationController
  before_action :signed_in_user, except: [:index, :show]
  before_action :set_shipping_request, only: [:show, :edit, :update, :destroy, :accept_bid]
  before_action :correct_sender, only: [:edit, :update, :destroy, :accept_bid]

  def index
    @shipping_requests = ShippingRequest.active
                                        .includes(:sender, :bids)
                                        .order(created_at: :desc)

    @shipping_requests = @shipping_requests.search_departure(params[:departure_city]) if params[:departure_city].present?
    @shipping_requests = @shipping_requests.search_arrival(params[:arrival_city]) if params[:arrival_city].present?

    if params[:max_weight].present? && params[:max_weight].to_f > 0
      @shipping_requests = @shipping_requests.by_max_weight(params[:max_weight].to_f)
    end

    if params[:date_from].present?
      parsed_date = Date.iso8601(params[:date_from]) rescue nil
      @shipping_requests = @shipping_requests.by_date(parsed_date) if parsed_date
    end

    @shipping_requests = @shipping_requests.paginate(page: params[:page], per_page: 12)
  end

  def show
    @bids = @shipping_request.bids
                             .includes(:traveler)
                             .order(Arel.sql("CASE status WHEN 'accepted' THEN 0 WHEN 'pending' THEN 1 ELSE 2 END, price_per_kg_cents ASC"))
    @bid = Bid.new(
      available_kg: @shipping_request.weight_kg,
      travel_date: @shipping_request.desired_date,
      currency: @shipping_request.currency
    )
    @tracking = @shipping_request.shipment_tracking
    @existing_user_bid = signed_in? ? @shipping_request.bids.find_by(traveler_id: current_user.id) : nil
    @can_review = signed_in? && eligible_to_review?
    @review = Review.new if @can_review
  end

  def new
    @shipping_request = current_user.shipping_requests.build(currency: "EUR")
  end

  def create
    @shipping_request = current_user.shipping_requests.build(shipping_request_params)
    if @shipping_request.save
      flash[:success] = t('shipping_requests.created')
      redirect_to @shipping_request
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @shipping_request.editable?
      flash[:error] = t('shipping_requests.cannot_edit')
      redirect_to @shipping_request
    end
  end

  def update
    unless @shipping_request.editable?
      flash[:error] = t('shipping_requests.cannot_edit')
      redirect_to @shipping_request and return
    end

    if @shipping_request.update(shipping_request_update_params)
      flash[:success] = t('shipping_requests.updated')
      redirect_to @shipping_request
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @shipping_request.cancellable?
      flash[:error] = t('shipping_requests.cannot_cancel')
      redirect_to @shipping_request and return
    end

    @shipping_request.cancel!
    flash[:success] = t('shipping_requests.cancelled')
    redirect_to my_requests_shipping_requests_path
  rescue ShippingRequest::InvalidActionError => e
    flash[:error] = e.message
    redirect_to @shipping_request
  end

  def accept_bid
    bid = @shipping_request.bids.find(params[:bid_id])
    tracking = @shipping_request.accept_bid!(bid)

    Notification.notify(
      bid.traveler,
      tracking,
      "bid_accepted",
      t('notifications.bid_accepted', title: @shipping_request.title)
    )

    flash[:success] = t('shipping_requests.bid_accepted')
    redirect_to shipment_tracking_path(tracking)
  rescue ShippingRequest::InvalidActionError => e
    flash[:error] = e.message
    redirect_to @shipping_request
  end

  def my_requests
    @shipping_requests = current_user.shipping_requests
                                     .includes(:bids, :shipment_tracking)
                                     .order(created_at: :desc)
                                     .paginate(page: params[:page], per_page: 12)
  end

  private

  def set_shipping_request
    @shipping_request = ShippingRequest.find(params[:id])
  end

  def correct_sender
    return if @shipping_request.sender_id == current_user.id

    flash[:error] = t('common.unauthorized')
    redirect_to root_url
  end

  def eligible_to_review?
    return false unless @shipping_request.status == "completed"
    accepted = @shipping_request.accepted_bid
    return false unless accepted
    return false unless current_user.id == @shipping_request.sender_id || current_user.id == accepted.traveler_id

    !@shipping_request.reviews.exists?(reviewer_id: current_user.id)
  end

  def shipping_request_params
    params.require(:shipping_request).permit(
      :title, :description, :weight_kg, :length_cm, :width_cm, :height_cm,
      :departure_city, :departure_country, :arrival_city, :arrival_country,
      :desired_date, :deadline_date, :max_budget_euros, :max_budget_cents,
      :declared_value_euros, :declared_value_cents,
      :currency, :item_category, :special_instructions, :prohibited_items_acknowledged
    )
  end

  def shipping_request_update_params
    params.require(:shipping_request).permit(
      :title, :description, :weight_kg, :length_cm, :width_cm, :height_cm,
      :departure_city, :departure_country, :arrival_city, :arrival_country,
      :desired_date, :deadline_date, :max_budget_euros, :max_budget_cents,
      :declared_value_euros, :declared_value_cents,
      :item_category, :special_instructions
    )
  end
end

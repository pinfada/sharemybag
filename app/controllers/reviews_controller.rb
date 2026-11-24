class ReviewsController < ApplicationController
  before_action :signed_in_user

  def create
    @shipping_request = ShippingRequest.find(params[:shipping_request_id])
    accepted_bid = @shipping_request.accepted_bid

    unless accepted_bid && participant?(@shipping_request, accepted_bid)
      flash[:error] = t('common.unauthorized')
      redirect_to @shipping_request and return
    end

    # Sécurité anti-IDOR : reviewee et role sont toujours déduits côté serveur
    if current_user.id == @shipping_request.sender_id
      reviewee = accepted_bid.traveler
      role = "sender"
    else
      reviewee = @shipping_request.sender
      role = "traveler"
    end

    @review = @shipping_request.reviews.build(review_params)
    @review.reviewer = current_user
    @review.reviewee = reviewee
    @review.role = role

    if @review.save
      Notification.notify(
        reviewee,
        @shipping_request,
        "new_review",
        t('notifications.new_review', name: current_user.name, rating: @review.rating)
      )
      flash[:success] = t('reviews.created')
    else
      flash[:error] = @review.errors.full_messages.join(" · ")
    end

    redirect_to @shipping_request.shipment_tracking ? shipment_tracking_path(@shipping_request.shipment_tracking) : @shipping_request
  end

  private

  def participant?(shipping_request, accepted_bid)
    current_user.id == shipping_request.sender_id || current_user.id == accepted_bid.traveler_id
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end

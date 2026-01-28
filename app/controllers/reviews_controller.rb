class ReviewsController < ApplicationController
  before_action :signed_in_user

  def create
    @shipping_request = ShippingRequest.find(params[:shipping_request_id])

    unless authorized_to_review?(@shipping_request)
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to @shipping_request and return
    end

    @review = @shipping_request.reviews.build(review_params)
    @review.reviewer = current_user

    if @review.save
      Notification.notify(@review.reviewee, @shipping_request, "new_review",
        I18n.t('notifications.new_review', name: current_user.name, rating: @review.rating))
      flash[:success] = I18n.t('reviews.created')
    else
      flash[:error] = @review.errors.full_messages.join(", ")
    end
    redirect_to @shipping_request
  end

  private

  def authorized_to_review?(shipping_request)
    accepted_bid = shipping_request.accepted_bid
    return false unless accepted_bid

    sender_id = shipping_request.sender_id
    traveler_id = accepted_bid.traveler_id

    current_user.id == sender_id || current_user.id == traveler_id
  end

  def review_params
    params.require(:review).permit(:reviewee_id, :rating, :comment, :role)
  end
end

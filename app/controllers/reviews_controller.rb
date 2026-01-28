class ReviewsController < ApplicationController
  before_action :signed_in_user

  def create
    @shipping_request = ShippingRequest.find(params[:shipping_request_id])
    @review = @shipping_request.reviews.build(review_params)
    @review.reviewer = current_user

    if @review.save
      Notification.notify(@review.reviewee, @shipping_request, "new_review",
        I18n.t('notifications.new_review', name: current_user.name, rating: @review.rating))

      flash[:success] = I18n.t('reviews.created')
      redirect_to @shipping_request
    else
      flash[:error] = @review.errors.full_messages.join(", ")
      redirect_to @shipping_request
    end
  end

  private

  def review_params
    params.require(:review).permit(:reviewee_id, :rating, :comment, :role)
  end
end

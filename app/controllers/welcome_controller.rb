class WelcomeController < ApplicationController
  def home
    @featured_requests = ShippingRequest.active
                                        .includes(:sender, :bids)
                                        .order(created_at: :desc)
                                        .limit(6)
    @open_requests_count = ShippingRequest.active.count
    @completed_shipments_count = ShipmentTracking.where(status: "confirmed").count
    @travelers_count = User.count
  end

  def how_it_works
  end

  def privacy
  end

  def accessibility
  end
end

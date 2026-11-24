class PassengerBookingsController < ApplicationController
  before_action :signed_in_user

  def index
    @bookings = current_user.passenger_bookings
                            .includes(flight: :aircraft_type)
                            .joins(:flight)
                            .order("flights.departure_at ASC")
    @active_orders = current_user.kilo_orders.active.includes(:flight, :passenger_booking).recent
    @recent_trades = KiloTrade.where("buyer_id = :uid OR seller_id = :uid", uid: current_user.id)
                              .includes(:flight, :buyer, :seller)
                              .recent
                              .limit(20)
  end
end

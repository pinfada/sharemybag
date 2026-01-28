class WelcomeController < ApplicationController
  before_action :prepare_search, only: [:search]

  def home
    if signed_in?
      @micropost  = current_user.microposts.build
      @feed_items = current_user.feed.paginate(page: params[:page], per_page: 30)
    end
  end

  def search
  end

  def listevol
  end

  def policy
  end

  def about
  end

  def team
  end

  def help
  end

  def contact
  end

  private

  def prepare_search
    @coordonnees = Coordonnee.includes(airport: [
      { arriving_flights: [{ bookings: [:user, :bagages] }, :provenance, :destination] }
    ]).paginate(page: params[:page], per_page: 20)

    @markers = @coordonnees.map do |c|
      { lat: c.latitude, lng: c.longitude, infowindow: c.titre }
    end

    @flights_data = []
    @coordonnees.each do |coordonnee|
      next unless coordonnee.airport
      coordonnee.airport.arriving_flights.each do |vol|
        vol.bookings.each do |resa|
          next unless resa.user_id && resa.vol_id
          user = resa.user
          next unless user
          bagages = user.bagages.select { |b| b.booking_id == resa.id && b.user_id == resa.user_id }
          next if bagages.empty?

          volume = bagages.sum { |b| b.longueur * b.largeur * b.hauteur }
          poids  = bagages.sum(&:poids)
          prix   = bagages.sum(&:prix)

          @flights_data << {
            user: user,
            booking: resa,
            vol: vol,
            departure: vol.provenance,
            arrival: vol.destination,
            nb_bagages: bagages.count,
            poids: poids,
            volume: volume,
            prix: prix
          }
        end
      end
    end
  end

  def search_params
    params.require(:search).permit!
  end
end

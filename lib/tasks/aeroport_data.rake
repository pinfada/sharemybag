namespace :aeroport_data do
    desc "alimentation base reservation"
    task populate: :environment do
      make_bookings
    end
end

def make_bookings
  Booking.delete_all  # suppression de la table des reservations
  Booking.reset_pk_sequence # remise de l'id à 1 pour table reservation
  Bagage.delete_all  # suppression de la table des reservations
  Bagage.reset_pk_sequence # remise de l'id à 1 pour table reservation
  vols = Vol.limit(100)
  users = User.limit(6)
  vols.each do |vol|
    users.each do |user|
      Booking.create!({ vol_id:  vol.id,
                        user_id: user.id })
      bagages = rand(3)
      booking = Booking.last
      bagages.times do 
        poids = Faker::Number.number(2)
        prix = Faker::Number.number(3)
        longueur = Faker::Number.number(2)
        largeur = Faker::Number.number(2)
        hauteur = Faker::Number.number(2)
        user.bagages.create!({poids: poids,
                          prix: prix,
                          longueur: longueur,
                          largeur: largeur,
                          hauteur: hauteur,
                          booking_id: booking.id})
      end
    end
  end
end
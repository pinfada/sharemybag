# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'open-uri'
require 'nokogiri'

Airport.delete_all # suppression de la table airport
Coordonnee.delete_all # suppression de la table coordonnee
Vol.delete_all     # suppression de la table vol
Airport.reset_pk_sequence # remise de l'id à 1 pour table airport
Vol.reset_pk_sequence # remise de l'id à 1 pour table vol
Coordonnee.reset_pk_sequence # remise de l'id à 1 pour table vol

def create_data
	avg_daily_flights = 2  # Create about this many flights each day
	days_in_future    = 85 # Earliest flight created is this days from now
	number_of_days    = 4  # Create flights till this number of days from
                         # the day of the earliest flight created

	create_airports
	create_flights(number_of_days, avg_daily_flights, days_in_future)
end

def create_airports
  url = "https://fr.wikipedia.org/wiki/Liste_des_a%C3%A9rodromes_en_France"
  data = Nokogiri::HTML(open(url))
  vols = data.css('tr')

  vols.each do |vol|
    # recuperation du code OACI
    code = vol.css('td[5]').text
    # recuperation de la commune
    getlocation = vol.css('td[3]').text

    if !getlocation.empty?
      if !code.empty? && code.length == 4
          Airport.create!(code: code, location: getlocation)
          identifiant = Airport.where(location: getlocation).pluck(:id)
          Coordonnee.create!(titre: getlocation, description:"Le Lorem Ipsum est simplement du faux texte", airport_id: identifiant.pop)
      end
    end
  end
end

def random_flight
  url = "https://www.tripadvisor.fr/Airlines"
  data = Nokogiri::HTML(open(url))
  liste_aeroports = data.css('.airline-name').text
  airlines = liste_aeroports.split "\n\n\n\n"
  "#{airlines.sample} #{rand(1900) + 100}"
end

def random_duration
  (rand(240) + 120).minutes
end

def random_start(days_from_now)
  days_from_now.days.from_now.midnight + (60 * (rand(60 * 24)))
end

def create_flights(num_of_days, daily_flights, days_in_future)
  airports = Airport.limit(20)

  airports.each do |provenance|
    airports.each do |destination|
      next if provenance == destination
      duree = random_duration
      (days_in_future...days_in_future + num_of_days).each do |days_from_now|
        date_depart = random_start(days_from_now)
        number_of_flights = daily_flights + (rand(7) - 3)
        number_of_flights.times do 
          Vol.create!({ num_vol:   random_flight,
                           date_depart:    date_depart,
                           duree:          duree,
                           provenance_id:  provenance.id,
                           destination_id: destination.id })
        end
      end
    end
  end
end

create_data
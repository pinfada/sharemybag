namespace :fly_data do
    desc "alimentation base reservation"
    task populate: :environment do
      make_scrappings
    end
end

def make_scrappings

  require 'open-uri'
  require 'nokogiri'

  base_url = 'http://fr.flightaware.com'
  base_dir = '/live/airport/LFPG/enroute?;offset='
  base_opt = ';order=estimatedarrivaltime;sort=ASC'

  directory = "C:/Users/Olivier/Desktop"
  $cpt = 0
  $tot_cpt = 60

  File.open(File.join(directory, 'test.txt'), 'w') do |f|
    begin
      puts("Inside the loop cpt = #$cpt" )
      url = base_url+base_dir+"#$cpt"+base_opt
      data = Nokogiri::HTML(open(url))
      vols = data.css('.smallrow1', '.smallrow2')
      vols.each do |vol|
        # recuperation du numero de vol
        num_vol = vol.at_css('td[1]')
        puts num_vol
        if num_vol.nil?
          f.puts "NUMERO VOL ABSENT"
        else
          num_vol.text.split
          f.puts num_vol
        end

        # recuperation type d'avion
        type_avion = vol.at_css('td[2]')
        puts type_avion
        if type_avion.nil?
          f.puts "TYPE AVION ABSENT"
        else
          type_avion.text.split
          f.puts type_avion
        end

        # recuperation de la destination
        destination = vol.at_css('td[3]')
        puts destination
        if destination.nil?
          f.puts "DESTINATION ABSENTE"
        else
          destination.text.split
          f.puts destination
        end

        # recuperation heure de départ
        hr_depart = vol.at_css('td[4]')
        puts hr_depart
        if hr_depart.nil?
          f.puts "HEURE DEPART ABSENTE"
        else
          hr_depart.text.split
          f.puts hr_depart
        end

        # recuperation heure d'arrivée estimée
        hr_esti_arrivee = vol.at_css('td[5]')
        puts hr_esti_arrivee
        if hr_esti_arrivee.nil?
          f.puts "HEURE ESTIMEE ARRIVEE ABSENTE"
        else
          hr_esti_arrivee.text.split
          f.puts hr_esti_arrivee
        end
      end
      # f.puts vols
      $cpt += 20;
    end until $cpt > $tot_cpt
  end 
end
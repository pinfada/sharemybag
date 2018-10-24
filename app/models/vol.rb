class Vol < ActiveRecord::Base
	belongs_to :provenance,   class_name: "Airport"
	belongs_to :destination,   class_name: "Airport"
	has_many   :bookings,     dependent: :destroy
	has_and_belongs_to_many   :users

	validates :num_vol, presence: true
	validates :date_depart,    presence: true
	validates :duree,      presence: true
	validates :provenance_id,    presence: true
	validates :destination_id,      presence: true
	
	def self.all_unique_future_vol_dates
		Vol.where("date_depart > :future", {future: Time.now.utc.tomorrow.midnight}).
		       select(:date_depart).order(date_depart: :asc).
		       map{|f| f.date_depart.utc.strftime('%d/%m/%Y')}.uniq
	end

	def self.search_vols(from_id, to_id, date_vol)
    	date_vol = Date.strptime(date_vol, "%d/%m/%Y")
    	Vol.where(provenance_id: from_id).where(destination_id: to_id).
           where("date_depart >= :start AND date_depart < :stop", 
           	     {start: date_vol.midnight, stop: date_vol.tomorrow.midnight}).
           order(:date_depart)
	end

	# Retourne les informations de vol de l'utilisateur.
  	def self.recherche_vol_user(user)
    	Vol.where(id: user).order(:id)
  	end
end

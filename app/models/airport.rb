class Airport < ActiveRecord::Base
#	attr_accessible :code, :location
	has_many :departing_flights, class_name:  "Vol", dependent: :destroy,
	                             foreign_key: "provenance_id"
	has_many :arriving_flights,  class_name:  "Vol", dependent: :destroy,
	                             foreign_key: "destination_id"
 	has_many :coordonnees
	validates :location, presence: true
end

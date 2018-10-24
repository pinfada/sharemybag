class Booking < ActiveRecord::Base
	before_validation :set_ref_number, on: :create
	belongs_to :vol
	belongs_to :user
	
	# Une reservation contient plusieurs bagages par utilisateurs/voyageurs
	has_many   :bagages

	validates :ref_number, presence: true

	private

	  def set_ref_number
	  	ref = ""
	  	3.times { ref += ('A'..'Z').to_a.sample }
	  	4.times { ref += ('0'..'9').to_a.sample }
	  	self.ref_number = ref
	  end
end

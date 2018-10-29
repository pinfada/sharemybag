class VolsController < ApplicationController
	before_action :signed_in_user
	before_action :search
	def index
		@airport_options = Airport.all.map do |airport|
			[airport.location, airport.id]
		end
		@bagage_options  = [1, 2, 3, 4]
		@dates = Vol.all_unique_future_vol_dates
		# Help maintain user's selection
		@provenance_selected = params[:provenance_id]
		@destination_selected   = params[:destination_id]
		@bagage_selected = params[:bagages]
		@date_selected = params[:flight_date]

		unless params[:provenance_id].nil?
			if params[:provenance_id] == params[:destination_id]
				flash.now[:error] = "Vos informations de départ et d'arrivée sont identiques!"
			else
				@matched_vols = Vol.search_vols(params[:provenance_id],
			                                           params[:destination_id],
			                                           params[:flight_date])
			end
		end
	end
end

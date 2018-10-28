module ApplicationHelper
	# Returns the full title on a per-page basis.
	def full_title(page_title)
		base_title = "ShareMyBag"
		if page_title.empty?
	   		base_title
		else
	   		"#{base_title} | #{page_title}"
		end
	end

  	def search
		@distance_options  = [10, 30, 60, 90]
		@vol_options       = ['Départ', 'Arrivée']
		@location_selected = params[:search]
	#	@distance_selected = params[:distance]
		@distance_selected = 30
		@vol_selected      = params[:type_vol]
		if params[:search].nil?
			@coordonnees = Coordonnee.paginate(page: params[:page], :per_page => 30)
		else
			@coordonnees = Coordonnee.near(@location_selected, @distance_selected, :units => :km)
			@coordonnees = @coordonnees.paginate(page: params[:page], :per_page => 30)
		end

		@hash = Gmaps4rails.build_markers(@coordonnees) do |coordonnee, marker|
			marker.lat coordonnee.latitude
			marker.lng coordonnee.longitude
			marker.infowindow coordonnee.description
		end

  	end
end

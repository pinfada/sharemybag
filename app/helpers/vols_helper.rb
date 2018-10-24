module VolsHelper
	def vol_name(id)
		Vol.find(id).num_vol
	end

	def depart(id)
		airport = Vol.find(id).provenance
		"#{airport.location} (#{airport.code})"
	end

	def arrivee(id)
		airport = Vol.find(id).destination
		"#{airport.location} (#{airport.code})"
	end

	def vol_datetime(id)
		dt = Vol.find(id).date_depart.utc
		"#{dt.strftime('%I:%M%p')} on #{dt.strftime('%a, %d %b')}"
	end

	def choix_entete_vol(from_id, to_id, flight_date)
		"Vols de #{Airport.find(from_id).code} à " \
		"#{Airport.find(to_id).code} le #{flight_date}"
	end

	def vol_label(vol)
		"#{vol.date_depart.strftime("%I:%M%p")} -- #{vol.num_vol}"
	end
end

class UserMailer < ApplicationMailer
	include VolsHelper

  default from: "noreply@exemple.com"

  def thank_you_email(user)
#  	bagage          = user.bagages
    booking         = user.bookings.last
  	@name           = user.name
  	@vols_info      = vol_info(user.vol)
  	@ref_number     = booking.ref_number
  	@url            = booking_url(user)
  	email_with_name = "#{user.name} <#{user.email}>"
  	mail(to: email_with_name, subject: "Merci pour votre reservation")
  end

	def vol_info(vol)
		from = vol.provenance
		to   = vol.destination
		"#{vol.num_vol} depart à #{vol_datetime(vol.id)} " \
		"from #{from.location} (#{from.code}) a #{to.location} (#{to.code})"
	end
end

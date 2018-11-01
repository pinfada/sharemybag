class BookingsController < ApplicationController
	#before_action :signed_in_user, only: [:create]
	before_action :search
	def new
	#	@bagage = current_user.bagages
		@bagage = Bagage.where(user_id: current_user, booking_id: nil)
		@vol = Vol.recherche_vol_user(current_user.vol_id)
		redirect_to root_path if @vol.nil?
		@booking = Booking.new
	end

	def create
		@booking = Booking.new
		if @booking.save
			# permet de recuperer les infos bagages de l'utilisateur
			@bagage = Bagage.where(user_id: current_user.id, booking_id: nil)
			# recuperation de l'id de l'utilisateur
			@identifiant = Booking.where(user_id: current_user.id).pluck(:id)
			@bagage.update(:booking_id => @identifiant.pop)
			@booking.update_attributes(:vol_id => current_user.vol_id, :user_id => current_user.id)
			send_thank_you_emails(current_user)
			
			flash[:success] = "Vol reservé avec succes!"
#			redirect_to @booking
			redirect_to root_path
		else
			@vol  = Vol.find(params[:vol_id])
			render 'new'
		end
	end

	def show
		if signed_in?
			@booking = Booking.find(params[:id])
			@bagage = Bagage.where(booking_id: @booking)
		else
			redirect_to root_path
		end
	end

	private

		# Never trust parameters from the scary internet, only allow the white list through.
		def booking_params
		  params.require(:booking).permit(:ref_number, :vol_id, :user_id)
		end

	  def send_thank_you_emails(users)
	  	UserMailer.thank_you_email(users).deliver
	  end

	  # Use callbacks to share common setup or constraints between actions.
      def set_booking
    	@booking = Booking.find(params[:id])
      end
end

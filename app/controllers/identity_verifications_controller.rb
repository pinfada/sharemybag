class IdentityVerificationsController < ApplicationController
  before_action :signed_in_user

  def new
    if current_user.identity_verification&.status == "verified"
      flash[:notice] = I18n.t('identity_verifications.already_verified', default: "Your identity is already verified.")
      redirect_to identity_verification_path and return
    end

    @verification = current_user.identity_verification || current_user.build_identity_verification
  end

  def create
    kyc_service = KycVerificationService.new(current_user)

    begin
      session = kyc_service.create_verification_session!(
        return_url: identity_verification_url(host: request.host_with_port)
      )

      redirect_to session.url, allow_other_host: true, status: :see_other
    rescue KycVerificationService::VerificationError => e
      flash[:error] = e.message
      redirect_to new_identity_verification_path
    rescue => e
      # Fallback to manual upload if Stripe Identity is not available
      @verification = current_user.build_identity_verification(verification_params)
      if @verification.save
        flash[:success] = I18n.t('identity_verifications.submitted', default: "Verification submitted for review.")
        redirect_to identity_verification_path
      else
        render :new
      end
    end
  end

  def show
    @verification = current_user.identity_verification

    unless @verification
      redirect_to new_identity_verification_path
      return
    end

    # Sync status with Stripe if pending
    if @verification.stripe_verification_session_id.present? && @verification.status == "pending"
      begin
        kyc_service = KycVerificationService.new(current_user)
        kyc_service.create_verification_session!(return_url: identity_verification_url(host: request.host_with_port))
      rescue
        # Ignore errors during status check
      end
    end
  end

  private

  def verification_params
    params.require(:identity_verification).permit(
      :document_type, :document_front_url, :document_back_url, :selfie_url
    )
  end
end

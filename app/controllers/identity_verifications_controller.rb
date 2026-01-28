class IdentityVerificationsController < ApplicationController
  before_action :signed_in_user

  def new
    @verification = current_user.build_identity_verification
  end

  def create
    @verification = current_user.build_identity_verification(verification_params)
    if @verification.save
      flash[:success] = I18n.t('identity_verifications.submitted')
      redirect_to current_user
    else
      render :new
    end
  end

  def show
    @verification = current_user.identity_verification
    redirect_to new_identity_verification_path unless @verification
  end

  private

  def verification_params
    params.require(:identity_verification).permit(
      :document_type, :document_front_url, :document_back_url, :selfie_url
    )
  end
end

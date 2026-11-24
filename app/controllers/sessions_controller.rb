class SessionsController < ApplicationController
  def new
    redirect_to shipping_requests_path if signed_in?
  end

  def create
    email = params.dig(:session, :email).to_s.strip.downcase
    password = params.dig(:session, :password).to_s

    user = email.present? ? User.find_by(email: email) : nil

    if user&.authenticate(password)
      sign_in(user)
      flash[:success] = t('auth.signed_in', name: user.name)
      redirect_back_or(shipping_requests_path)
    else
      flash.now[:error] = t('auth.invalid_credentials')
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    flash[:notice] = t('auth.signed_out')
    redirect_to root_url
  end
end

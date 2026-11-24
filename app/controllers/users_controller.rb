class UsersController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update]
  before_action :set_user, only: [:show, :edit, :update]
  before_action :correct_user, only: [:edit, :update]

  def show
    @completed_trades_count = @user.completed_trades_count
    @booked_flights_count = @user.passenger_bookings.count
  end

  def new
    redirect_to flights_path if signed_in?
    @user = User.new
  end

  def create
    @user = User.new(user_create_params)
    if @user.save
      sign_in(@user)
      flash[:success] = t("auth.welcome", name: @user.name)
      redirect_to flights_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_update_params)
      flash[:success] = t("users.profile_updated")
      redirect_to @user
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def correct_user
    return if current_user?(@user)

    flash[:error] = t("common.unauthorized")
    redirect_to root_url
  end

  def user_create_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :city, :country)
  end

  def user_update_params
    permitted = params.require(:user).permit(:name, :city, :country, :bio, :password, :password_confirmation)
    if permitted[:password].blank?
      permitted.delete(:password)
      permitted.delete(:password_confirmation)
    end
    permitted
  end
end

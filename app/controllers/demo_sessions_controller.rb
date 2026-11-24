class DemoSessionsController < ApplicationController
  PERSONA_EMAILS = {
    "light_passenger" => "marie@example.com",
    "heavy_passenger" => "pierre@example.com",
    "airline_vp"      => "vp@airfrance-demo.com"
  }.freeze

  def create
    email = PERSONA_EMAILS[params[:persona].to_s]
    user = email ? User.find_by(email: email) : nil

    unless user
      flash[:error] = "Demo persona unavailable."
      return redirect_to signin_path
    end

    sign_in(user)
    flash[:success] = "Switched to demo persona: #{user.name} (#{persona_label(params[:persona].to_s)})."
    redirect_to safe_return_path(params[:return_to])
  end

  private

  def safe_return_path(target)
    return flights_path if target.blank?
    str = target.to_s
    (str.start_with?("/") && !str.start_with?("//")) ? str : flights_path
  end

  def persona_label(key)
    case key
    when "light_passenger" then "Light Traveler · Seller"
    when "heavy_passenger" then "Heavy Traveler · Buyer"
    when "airline_vp"      then "Airline Revenue VP"
    else "Demo"
    end
  end
end

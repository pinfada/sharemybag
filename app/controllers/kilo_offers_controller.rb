class KiloOffersController < ApplicationController
  before_action :signed_in_user
  before_action :set_kilo_offer, only: [:show, :edit, :update, :destroy]
  before_action :correct_traveler, only: [:edit, :update, :destroy]

  def index
    @kilo_offers = KiloOffer.active
                            .includes(:traveler)
                            .order(travel_date: :asc)
                            .paginate(page: params[:page], per_page: 20)

    if params[:departure_city].present?
      @kilo_offers = @kilo_offers.where("LOWER(departure_city) LIKE ?", "%#{params[:departure_city].downcase}%")
    end
    if params[:arrival_city].present?
      @kilo_offers = @kilo_offers.where("LOWER(arrival_city) LIKE ?", "%#{params[:arrival_city].downcase}%")
    end
    if params[:min_kg].present?
      @kilo_offers = @kilo_offers.by_min_weight(params[:min_kg])
    end
    if params[:sort] == "price"
      @kilo_offers = @kilo_offers.cheapest_first
    end
  end

  def show
    @traveler = @kilo_offer.traveler
  end

  def new
    @kilo_offer = current_user.kilo_offers.build
  end

  def create
    @kilo_offer = current_user.kilo_offers.build(kilo_offer_params)
    if @kilo_offer.save
      flash[:success] = I18n.t('kilo_offers.created')
      redirect_to @kilo_offer
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @kilo_offer.update(kilo_offer_params)
      flash[:success] = I18n.t('kilo_offers.updated')
      redirect_to @kilo_offer
    else
      render :edit
    end
  end

  def destroy
    @kilo_offer.update(status: "expired")
    flash[:success] = I18n.t('kilo_offers.removed')
    redirect_to kilo_offers_path
  end

  def my_offers
    @kilo_offers = current_user.kilo_offers
                               .order(created_at: :desc)
                               .paginate(page: params[:page], per_page: 20)
  end

  private

  def set_kilo_offer
    @kilo_offer = KiloOffer.find(params[:id])
  end

  def correct_traveler
    redirect_to root_url unless @kilo_offer.traveler_id == current_user.id
  end

  def kilo_offer_params
    params.require(:kilo_offer).permit(
      :departure_city, :departure_country, :arrival_city, :arrival_country,
      :travel_date, :available_kg, :price_per_kg_cents, :currency,
      :accepted_items, :restrictions, :flight_number, :vol_id
    )
  end
end

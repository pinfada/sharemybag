class CustomsDeclarationsController < ApplicationController
  before_action :signed_in_user
  before_action :set_shipping_request
  before_action :authorize_sender

  def new
    service = CustomsComplianceService.new(@shipping_request)
    unless service.requires_customs_declaration?
      flash[:notice] = I18n.t('customs.not_required', default: "Customs declaration is not required for this route.")
      redirect_to @shipping_request and return
    end

    @declaration = @shipping_request.customs_declaration || CustomsDeclaration.new(
      origin_country: @shipping_request.departure_country,
      destination_country: @shipping_request.arrival_country
    )
    @prohibited_items = ProhibitedItem.active.universal
  end

  def create
    service = CustomsComplianceService.new(@shipping_request)
    result = service.create_declaration!(declaration_params.merge(
      sender_attestation: params.dig(:customs_declaration, :sender_attestation) == "1"
    ))

    if result[:validation][:valid]
      flash[:success] = I18n.t('customs.submitted', default: "Customs declaration submitted and validated.")
      redirect_to @shipping_request
    else
      flash[:error] = result[:validation][:errors].join(". ")
      @declaration = result[:declaration]
      @prohibited_items = ProhibitedItem.active.universal
      render :new
    end
  end

  def show
    @declaration = @shipping_request.customs_declaration
    redirect_to new_shipping_request_customs_declaration_path(@shipping_request) unless @declaration
  end

  private

  def set_shipping_request
    @shipping_request = ShippingRequest.find(params[:shipping_request_id])
  end

  def authorize_sender
    unless @shipping_request.sender_id == current_user.id
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end

  def declaration_params
    params.require(:customs_declaration).permit(
      :total_declared_value_cents, :currency, :purpose,
      :contains_food, :contains_plants, :contains_animal_products,
      :contains_medicine, :contains_electronics, :contains_currency,
      :currency_amount_declared, :item_descriptions, :dangerous_goods_declared
    )
  end
end

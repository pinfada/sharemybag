class PaymentsController < ApplicationController
  before_action :signed_in_user
  before_action :set_transaction, only: [:checkout, :success, :cancel, :status]

  # POST /payments/checkout
  def checkout
    authorize_sender!

    service = StripePaymentService.new(@transaction)

    begin
      session = service.create_checkout_session!(
        success_url: payment_success_url(@transaction, host: request.host_with_port),
        cancel_url: payment_cancel_url(@transaction, host: request.host_with_port)
      )

      redirect_to session.url, allow_other_host: true, status: :see_other
    rescue StripePaymentService::AccountNotReadyError
      flash[:error] = I18n.t('payments.traveler_account_not_ready')
      redirect_to shipping_request_path(@transaction.shipping_request)
    rescue StripePaymentService::PaymentError => e
      flash[:error] = I18n.t('payments.error', message: e.message)
      redirect_to shipping_request_path(@transaction.shipping_request)
    end
  end

  # GET /payments/:id/success
  def success
    authorize_sender!
    flash[:success] = I18n.t('payments.success')
    redirect_to shipment_tracking_path(@transaction.shipping_request.shipment_tracking || @transaction.shipping_request)
  end

  # GET /payments/:id/cancel
  def cancel
    authorize_sender!
    flash[:notice] = I18n.t('payments.cancelled')
    redirect_to shipping_request_path(@transaction.shipping_request)
  end

  # GET /payments/:id/status
  def status
    authorize_participant!
    render json: {
      status: @transaction.status,
      amount: @transaction.amount,
      currency: @transaction.currency,
      paid_at: @transaction.paid_at,
      released_at: @transaction.released_at
    }
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def authorize_sender!
    unless current_user.id == @transaction.sender_id
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end

  def authorize_participant!
    unless current_user.id.in?([@transaction.sender_id, @transaction.traveler_id])
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end
end

class DisputesController < ApplicationController
  before_action :signed_in_user
  before_action :set_dispute, only: [:show, :add_evidence, :add_message, :escalate, :resolve, :close]
  before_action :authorize_participant, only: [:show, :add_evidence, :add_message]
  before_action :authorize_admin, only: [:admin_index, :escalate, :resolve]

  # GET /disputes
  def index
    @disputes = Dispute.where(
      "opened_by_id = ? OR shipping_request_id IN (?)",
      current_user.id,
      current_user.shipping_requests.select(:id)
    ).or(
      Dispute.joins(:transaction).where(transactions: { traveler_id: current_user.id })
    ).recent.paginate(page: params[:page], per_page: 20)
  end

  # GET /disputes/:id
  def show
    @messages = @dispute.dispute_messages
    @messages = @messages.public_messages unless current_user.admin?
    @messages = @messages.chronological
    @evidences = @dispute.dispute_evidences.order(created_at: :desc)
  end

  # GET /disputes/new?shipping_request_id=X
  def new
    @shipping_request = ShippingRequest.find(params[:shipping_request_id])
    @dispute = Dispute.new
  end

  # POST /disputes
  def create
    @shipping_request = ShippingRequest.find(params[:shipping_request_id])
    service = DisputeResolutionService.new

    begin
      @dispute = service.open_dispute!(
        shipping_request: @shipping_request,
        user: current_user,
        params: dispute_params
      )
      flash[:success] = I18n.t('disputes.opened')
      redirect_to @dispute
    rescue DisputeResolutionService::DisputeError => e
      flash[:error] = e.message
      @dispute = Dispute.new(dispute_params)
      render :new
    end
  end

  # POST /disputes/:id/evidence
  def add_evidence
    service = DisputeResolutionService.new(@dispute)

    begin
      service.add_evidence!(user: current_user, params: evidence_params)
      flash[:success] = I18n.t('disputes.evidence_added')
    rescue DisputeResolutionService::DisputeError => e
      flash[:error] = e.message
    end

    redirect_to @dispute
  end

  # POST /disputes/:id/message
  def add_message
    service = DisputeResolutionService.new(@dispute)

    begin
      service.add_message!(
        user: current_user,
        body: params[:body],
        is_internal: current_user.admin? && params[:is_internal] == "true"
      )
      flash[:success] = I18n.t('disputes.message_sent')
    rescue DisputeResolutionService::DisputeError => e
      flash[:error] = e.message
    end

    redirect_to @dispute
  end

  # POST /disputes/:id/escalate (admin)
  def escalate
    service = DisputeResolutionService.new(@dispute)
    service.escalate!(reason: params[:reason] || "Manually escalated by admin")
    flash[:success] = I18n.t('disputes.escalated')
    redirect_to @dispute
  end

  # POST /disputes/:id/resolve (admin)
  def resolve
    service = DisputeResolutionService.new(@dispute)

    begin
      service.resolve!(
        resolver: current_user,
        resolution_type: params[:resolution_type],
        amount_cents: params[:resolution_amount_cents]&.to_i,
        notes: params[:resolution_notes]
      )
      flash[:success] = I18n.t('disputes.resolved')
    rescue DisputeResolutionService::DisputeError => e
      flash[:error] = e.message
    end

    redirect_to @dispute
  end

  # POST /disputes/:id/close
  def close
    unless current_user.admin? || current_user.id == @dispute.opened_by_id
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url and return
    end

    @dispute.update!(status: 'closed', last_activity_at: Time.current)
    flash[:success] = I18n.t('disputes.closed')
    redirect_to disputes_path
  end

  # GET /admin/disputes (admin)
  def admin_index
    @disputes = Dispute.includes(:shipping_request, :opened_by, :transaction)
                       .recent.paginate(page: params[:page], per_page: 30)

    @disputes = @disputes.where(status: params[:status]) if params[:status].present?
    @disputes = @disputes.where(priority: params[:priority]) if params[:priority].present?
    @disputes = @disputes.where(dispute_type: params[:type]) if params[:type].present?
  end

  private

  def set_dispute
    @dispute = Dispute.find(params[:id])
  end

  def authorize_participant
    participant_ids = [
      @dispute.opened_by_id,
      @dispute.transaction.sender_id,
      @dispute.transaction.traveler_id,
      @dispute.assigned_to_id
    ].compact

    unless current_user.id.in?(participant_ids) || current_user.admin?
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end

  def authorize_admin
    unless current_user.admin?
      flash[:error] = I18n.t('common.unauthorized', default: "Unauthorized")
      redirect_to root_url
    end
  end

  def dispute_params
    params.require(:dispute).permit(:dispute_type, :title, :description)
  end

  def evidence_params
    params.require(:evidence).permit(:evidence_type, :file_url, :description, :mime_type, :file_size_bytes)
  end
end

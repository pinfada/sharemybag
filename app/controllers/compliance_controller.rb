class ComplianceController < ApplicationController
  before_action :signed_in_user
  before_action :set_shipping_request
  before_action :authorize_sender, only: [:checklist, :submit_checklist]
  before_action :authorize_admin, only: [:admin_review, :approve, :reject]

  def checklist
    @checklist = @shipping_request.compliance_checklist ||
      @shipping_request.build_compliance_checklist(completed_by: current_user)
    @prohibited_items_categories = ProhibitedItem::CATEGORIES
    @customs_required = CustomsComplianceService.new(@shipping_request).requires_customs_declaration?
  end

  def submit_checklist
    orchestrator = ComplianceOrchestratorService.new(@shipping_request)
    @results = orchestrator.run_all_checks!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if @results[:passed]
      flash[:success] = I18n.t('compliance.passed', default: "All compliance checks passed! Your shipment is cleared.")
      redirect_to @shipping_request
    else
      flash[:error] = I18n.t('compliance.failed', default: "Some compliance checks failed. Please review the issues below.")
      @checklist = @shipping_request.compliance_checklist
      @errors = @results[:errors]
      @warnings = @results[:warnings]
      render :checklist
    end
  end

  def admin_review
    @pending = ShippingRequest.where(compliance_status: "flagged")
                              .includes(:sender, :compliance_checklist, :customs_declaration)
                              .order(created_at: :desc)
                              .paginate(page: params[:page], per_page: 20)
  end

  def approve
    @shipping_request.update!(compliance_status: "cleared", compliance_checked_at: Time.current)
    flash[:success] = "Shipment ##{@shipping_request.id} compliance approved."
    redirect_to admin_compliance_review_path
  end

  def reject
    @shipping_request.update!(compliance_status: "rejected", compliance_checked_at: Time.current)
    Notification.notify(@shipping_request.sender, @shipping_request, "compliance_rejected",
      "Your shipment request has been rejected for compliance reasons.")
    flash[:success] = "Shipment ##{@shipping_request.id} compliance rejected."
    redirect_to admin_compliance_review_path
  end

  private

  def set_shipping_request
    @shipping_request = ShippingRequest.find(params[:shipping_request_id] || params[:id])
  end

  def authorize_sender
    unless @shipping_request.sender_id == current_user.id
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
end

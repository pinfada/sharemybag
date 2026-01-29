class DisputeResolutionService
  OPENING_WINDOW_HOURS = 48
  AUTO_ESCALATION_HOURS = 72
  RESPONSE_DEADLINE_HOURS = 48

  class DisputeError < StandardError; end

  def initialize(dispute = nil)
    @dispute = dispute
  end

  # Open a new dispute
  def open_dispute!(shipping_request:, user:, params:)
    validate_opening_eligibility!(shipping_request, user)

    transaction = shipping_request.transaction
    raise DisputeError, "No transaction found for this request" unless transaction

    dispute = Dispute.create!(
      shipping_request: shipping_request,
      transaction: transaction,
      opened_by: user,
      dispute_type: params[:dispute_type],
      title: params[:title],
      description: params[:description],
      priority: determine_priority(params[:dispute_type], transaction.amount_cents),
      status: 'opened',
      auto_escalate_at: AUTO_ESCALATION_HOURS.hours.from_now,
      response_deadline_at: RESPONSE_DEADLINE_HOURS.hours.from_now,
      last_activity_at: Time.current
    )

    # Block funds
    transaction.update!(status: 'disputed', disputed_at: Time.current) unless transaction.status == 'disputed'

    # Notify the other party
    other_party = user.id == shipping_request.sender_id ?
                  transaction.traveler : shipping_request.sender

    Notification.notify(
      other_party, dispute, "dispute_opened",
      "A dispute has been opened: #{dispute.title}"
    )

    # Notify admin
    admin = User.find_by(admin: true)
    if admin
      Notification.notify(admin, dispute, "new_dispute", "New dispute ##{dispute.id}: #{dispute.title}")
    end

    @dispute = dispute
    dispute
  end

  # Add evidence to a dispute
  def add_evidence!(user:, params:)
    raise DisputeError, "Dispute is closed" if @dispute.status.in?(%w[resolved closed rejected])

    evidence = @dispute.dispute_evidences.create!(
      submitted_by: user,
      evidence_type: params[:evidence_type],
      file_url: params[:file_url],
      description: params[:description],
      content_hash: params[:file_url].present? ? Digest::SHA256.hexdigest(params[:file_url]) : nil,
      mime_type: params[:mime_type],
      file_size_bytes: params[:file_size_bytes]
    )

    @dispute.update!(last_activity_at: Time.current)

    evidence
  end

  # Add message to dispute thread
  def add_message!(user:, body:, is_internal: false)
    raise DisputeError, "Dispute is closed" if @dispute.status.in?(%w[resolved closed rejected])

    message = @dispute.dispute_messages.create!(
      sender: user,
      body: body,
      is_internal: is_internal
    )

    @dispute.update!(last_activity_at: Time.current)

    # Notify other participants
    participants = [@dispute.opened_by, @dispute.transaction.sender, @dispute.transaction.traveler, @dispute.assigned_to].compact.uniq
    participants.reject { |p| p.id == user.id }.each do |participant|
      next if is_internal && !participant.admin?
      Notification.notify(participant, @dispute, "dispute_message", "New message in dispute ##{@dispute.id}")
    end

    message
  end

  # Escalate dispute to mediation team
  def escalate!(reason: "Auto-escalated after #{AUTO_ESCALATION_HOURS}h")
    @dispute.update!(
      status: 'escalated',
      escalated_at: Time.current,
      priority: 'high',
      last_activity_at: Time.current,
      metadata: (@dispute.metadata || {}).merge(escalation_reason: reason)
    )

    admin = User.find_by(admin: true)
    if admin
      Notification.notify(admin, @dispute, "dispute_escalated", "Dispute ##{@dispute.id} escalated: #{reason}")
    end
  end

  # Resolve dispute with decision
  def resolve!(resolver:, resolution_type:, amount_cents: nil, notes: nil)
    raise DisputeError, "Only admin can resolve disputes" unless resolver.admin?

    ActiveRecord::Base.transaction do
      @dispute.update!(
        status: 'resolved',
        resolution_type: resolution_type,
        resolution_amount_cents: amount_cents,
        resolution_currency: @dispute.transaction.currency,
        resolution_notes: notes,
        resolved_at: Time.current,
        resolved_by: resolver,
        last_activity_at: Time.current
      )

      process_resolution!(resolution_type, amount_cents)

      # Notify both parties
      [@dispute.transaction.sender, @dispute.transaction.traveler].each do |party|
        Notification.notify(
          party, @dispute, "dispute_resolved",
          "Dispute ##{@dispute.id} resolved: #{resolution_type.humanize}"
        )
      end
    end
  end

  # Auto-escalate overdue disputes (called by scheduled job)
  def self.auto_escalate_overdue!
    Dispute.where(status: %w[opened under_review evidence_requested])
           .where("auto_escalate_at <= ?", Time.current)
           .find_each do |dispute|
      new(dispute).escalate!(reason: "No response within #{AUTO_ESCALATION_HOURS} hours")
    end
  end

  private

  def validate_opening_eligibility!(shipping_request, user)
    tracking = shipping_request.shipment_tracking

    if tracking&.delivered_at.present? && tracking.delivered_at < OPENING_WINDOW_HOURS.hours.ago
      raise DisputeError, "Dispute window has expired (#{OPENING_WINDOW_HOURS}h after delivery)"
    end

    unless user.id == shipping_request.sender_id ||
           user.id == shipping_request.transaction&.traveler_id
      raise DisputeError, "Only sender or traveler can open a dispute"
    end

    existing = Dispute.where(shipping_request: shipping_request)
                      .where.not(status: %w[resolved closed rejected])
                      .exists?
    raise DisputeError, "An active dispute already exists for this request" if existing
  end

  def determine_priority(dispute_type, amount_cents)
    case dispute_type
    when 'non_delivered' then amount_cents > 5000 ? 'urgent' : 'high'
    when 'damaged' then 'high'
    when 'wrong_content' then 'normal'
    when 'excessive_delay' then 'normal'
    else 'normal'
    end
  end

  def process_resolution!(resolution_type, amount_cents)
    transaction = @dispute.transaction
    payment_service = StripePaymentService.new(transaction)

    case resolution_type
    when 'full_refund'
      payment_service.refund!(reason: 'dispute_resolved')
    when 'partial_refund'
      payment_service.refund!(reason: 'dispute_resolved', partial_amount_cents: amount_cents) if amount_cents
    when 'no_refund'
      payment_service.release_funds! if transaction.status == 'disputed'
    when 'compensation'
      # Refund sender and compensate from platform
      payment_service.refund!(reason: 'dispute_resolved', partial_amount_cents: amount_cents) if amount_cents
    end
  rescue StripePaymentService::PaymentError => e
    Rails.logger.error("Resolution payment failed: #{e.message}")
    @dispute.update!(metadata: (@dispute.metadata || {}).merge(payment_error: e.message))
  end
end

class DisputeMailer < ApplicationMailer
  def dispute_opened(dispute, recipient)
    @dispute = dispute
    @recipient = recipient

    mail(
      to: recipient.email,
      subject: I18n.t('mailers.dispute.opened_subject', id: dispute.id, default: "Dispute ##{dispute.id} opened")
    )
  end

  def dispute_resolved(dispute, recipient)
    @dispute = dispute
    @recipient = recipient

    mail(
      to: recipient.email,
      subject: I18n.t('mailers.dispute.resolved_subject', id: dispute.id, default: "Dispute ##{dispute.id} resolved")
    )
  end

  def dispute_escalated(dispute, recipient)
    @dispute = dispute
    @recipient = recipient

    mail(
      to: recipient.email,
      subject: I18n.t('mailers.dispute.escalated_subject', id: dispute.id, default: "Dispute ##{dispute.id} escalated")
    )
  end
end

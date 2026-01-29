class AutoEscalateDisputesJob < ApplicationJob
  queue_as :default

  def perform
    DisputeResolutionService.auto_escalate_overdue!
    Rails.logger.info("[AutoEscalateDisputesJob] Checked for overdue disputes at #{Time.current}")
  end
end

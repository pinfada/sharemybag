class ComplianceChecklist < ActiveRecord::Base
  belongs_to :shipping_request
  belongs_to :completed_by, class_name: "User"

  SENDER_ATTESTATIONS = %i[
    no_prohibited_items no_dangerous_goods accurate_description
    accurate_weight proper_packaging customs_compliant
    accepts_liability accepts_inspection
  ].freeze

  SECURITY_CHECKS = %i[
    identity_verified security_screening_passed
    sanctions_check_passed customs_declaration_filed
  ].freeze

  AIRLINE_CHECKS = %i[
    airline_policy_checked weight_within_limits dimensions_within_limits
  ].freeze

  validates :shipping_request_id, uniqueness: true

  def all_sender_attestations_complete?
    SENDER_ATTESTATIONS.all? { |attr| send(attr) }
  end

  def all_security_checks_passed?
    SECURITY_CHECKS.all? { |attr| send(attr) }
  end

  def all_airline_checks_passed?
    AIRLINE_CHECKS.all? { |attr| send(attr) }
  end

  def fully_compliant?
    all_sender_attestations_complete? && all_security_checks_passed? && all_airline_checks_passed?
  end

  def mark_complete!(ip_address: nil, user_agent: nil)
    update!(
      fully_compliant: fully_compliant?,
      completed_at: Time.current,
      completed_ip: ip_address,
      user_agent: user_agent
    )
  end

  def compliance_percentage
    total = SENDER_ATTESTATIONS.size + SECURITY_CHECKS.size + AIRLINE_CHECKS.size
    passed = (SENDER_ATTESTATIONS + SECURITY_CHECKS + AIRLINE_CHECKS).count { |attr| send(attr) }
    ((passed.to_f / total) * 100).round
  end
end

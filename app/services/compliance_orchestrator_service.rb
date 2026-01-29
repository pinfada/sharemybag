class ComplianceOrchestratorService
  class ComplianceFailedError < StandardError; end

  attr_reader :shipping_request, :results

  def initialize(shipping_request)
    @shipping_request = shipping_request
    @results = { passed: true, checks: {}, errors: [], warnings: [] }
  end

  def run_all_checks!(ip_address: nil, user_agent: nil)
    # 1. Prohibited Items Screening
    run_prohibited_items_check!

    # 2. Security/Sanctions Screening
    run_security_screening!

    # 3. Customs Declaration (if cross-border)
    run_customs_check!

    # 4. Airline Policy Check (if flight known)
    run_airline_policy_check!

    # 5. KYC Verification Check
    run_kyc_check!

    # 6. Update compliance checklist
    update_checklist!(ip_address: ip_address, user_agent: user_agent)

    # 7. Update shipping request compliance status
    new_status = results[:passed] ? "cleared" : "flagged"
    shipping_request.update!(
      compliance_status: new_status,
      compliance_checked_at: Time.current
    )

    results
  end

  private

  def run_prohibited_items_check!
    service = ProhibitedItemsService.new(shipping_request)
    check_result = service.screen_contents!

    results[:checks][:prohibited_items] = check_result
    unless check_result[:passed]
      results[:passed] = false
      results[:errors] += check_result[:blocked_items].map { |i| "Prohibited: #{i[:keyword] || i[:reason]}" }
    end
    results[:warnings] += check_result[:warnings].map { |w| w[:reason] }
  end

  def run_security_screening!
    service = SecurityScreeningService.new(shipping_request.sender)
    screening = service.screen_user!

    results[:checks][:security_screening] = { status: screening.status, type: screening.screening_type }
    unless screening.cleared?
      results[:passed] = false
      results[:errors] << "Security screening failed: #{screening.matched_list || screening.status}"
    end
  rescue SecurityScreeningService::SanctionsMatchError => e
    results[:passed] = false
    results[:errors] << "Sanctions match: #{e.message}"
    results[:checks][:security_screening] = { status: "blocked" }
  end

  def run_customs_check!
    service = CustomsComplianceService.new(shipping_request)

    if service.requires_customs_declaration?
      declaration = shipping_request.customs_declaration
      if declaration.nil?
        results[:warnings] << "Customs declaration required for international shipment"
        results[:checks][:customs] = { status: "declaration_required" }
      else
        validation = service.validate_declaration!(declaration)
        results[:checks][:customs] = validation
        unless validation[:valid]
          results[:passed] = false
          results[:errors] += validation[:errors]
        end
      end
    else
      results[:checks][:customs] = { status: "not_required", reason: "Same customs zone" }
    end
  end

  def run_airline_policy_check!
    bid = shipping_request.accepted_bid
    return unless bid&.flight_number.present?

    airline_code = bid.flight_number[0..1].upcase
    policy = AirlinePolicy.find_by(airline_code: airline_code, active: true)

    unless policy
      results[:checks][:airline_policy] = { status: "unknown_airline", airline: airline_code }
      results[:warnings] << "Airline policy not found for #{airline_code}"
      return
    end

    airline_result = { airline: policy.airline_name, checks: [] }

    unless policy.allows_third_party?
      results[:passed] = false
      airline_result[:checks] << { check: "third_party", passed: false }
      results[:errors] << "#{policy.airline_name} does not allow third-party items"
    end

    weight_ok = policy.weight_compliant?(shipping_request.weight_kg)
    airline_result[:checks] << { check: "weight", passed: weight_ok, limit: policy.max_checked_weight_kg }
    unless weight_ok
      results[:warnings] << "Weight exceeds #{policy.airline_name} limit"
    end

    results[:checks][:airline_policy] = airline_result
  end

  def run_kyc_check!
    sender = shipping_request.sender
    verified = sender.verified?

    results[:checks][:kyc] = { verified: verified }
    unless verified
      results[:warnings] << "Sender identity not verified"
    end
  end

  def update_checklist!(ip_address: nil, user_agent: nil)
    checklist = shipping_request.compliance_checklist ||
      shipping_request.build_compliance_checklist(completed_by: shipping_request.sender)

    prohibited_check = results[:checks][:prohibited_items]
    security_check = results[:checks][:security_screening]
    customs_check = results[:checks][:customs]
    kyc_check = results[:checks][:kyc]

    checklist.assign_attributes(
      no_prohibited_items: prohibited_check&.dig(:passed) != false,
      no_dangerous_goods: !shipping_request.contains_dangerous_goods?,
      identity_verified: kyc_check&.dig(:verified) == true,
      security_screening_passed: security_check&.dig(:status) == "cleared",
      sanctions_check_passed: security_check&.dig(:status) != "blocked",
      customs_declaration_filed: customs_check&.dig(:status) != "declaration_required"
    )

    checklist.mark_complete!(ip_address: ip_address, user_agent: user_agent)
    checklist
  end
end

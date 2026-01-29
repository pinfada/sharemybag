class CustomsComplianceService
  class ComplianceError < StandardError; end

  # Countries requiring customs declaration for any import
  STRICT_CUSTOMS_COUNTRIES = %w[US CA AU NZ JP KR CN IN BR].freeze

  # EU Schengen zone (no customs between members)
  EU_SCHENGEN = %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE].freeze

  # CEMAC/UEMOA zones (West/Central Africa)
  UEMOA = %w[BJ BF CI GW ML NE SN TG].freeze
  CEMAC = %w[CM CF TD CG GA GQ].freeze

  attr_reader :shipping_request

  def initialize(shipping_request)
    @shipping_request = shipping_request
  end

  def requires_customs_declaration?
    return false if same_customs_zone?
    true
  end

  def same_customs_zone?
    origin = shipping_request.departure_country
    destination = shipping_request.arrival_country

    return true if origin == destination
    return true if EU_SCHENGEN.include?(origin) && EU_SCHENGEN.include?(destination)
    return true if UEMOA.include?(origin) && UEMOA.include?(destination)
    return true if CEMAC.include?(origin) && CEMAC.include?(destination)

    false
  end

  def validate_declaration!(declaration)
    errors = []

    # Validate items against prohibited list
    declaration.parsed_items.each do |item|
      desc = item.is_a?(Hash) ? item["description"] : item.to_s
      prohibited = ProhibitedItem.check_item(desc, country: declaration.destination_country)
      if prohibited.any? { |p| p.universally_prohibited? }
        errors << "Item '#{desc}' contains prohibited content"
      end
    end

    # Check currency declaration requirements
    if declaration.contains_currency && (declaration.currency_amount_declared.nil? || declaration.currency_amount_declared <= 0)
      errors << "Currency amount must be declared when transporting cash"
    end

    # Check if currency exceeds reporting threshold (typically 10,000€)
    if declaration.contains_currency && declaration.currency_amount_declared.to_i > 1000000
      errors << "Currency amount exceeds €10,000 reporting threshold — requires customs office declaration"
    end

    # Validate food/plant imports
    if declaration.contains_food && STRICT_CUSTOMS_COUNTRIES.include?(declaration.destination_country)
      errors << "Food imports require phytosanitary certificate for #{declaration.destination_country}"
    end

    if declaration.contains_plants && STRICT_CUSTOMS_COUNTRIES.include?(declaration.destination_country)
      errors << "Plant imports require phytosanitary certificate for #{declaration.destination_country}"
    end

    if declaration.contains_animal_products
      errors << "Animal products may require veterinary certificate"
    end

    if declaration.contains_medicine
      errors << "Medicines require prescription or medical certificate for international transport"
    end

    if errors.any?
      declaration.update!(status: "flagged", validation_results: { errors: errors })
      return { valid: false, errors: errors }
    end

    declaration.update!(status: "validated", validation_results: { errors: [], validated_at: Time.current.iso8601 })
    { valid: true, errors: [] }
  end

  def create_declaration!(params)
    declaration = CustomsDeclaration.new(
      shipping_request: shipping_request,
      declared_by: shipping_request.sender,
      origin_country: shipping_request.departure_country,
      destination_country: shipping_request.arrival_country,
      **params
    )

    declaration.attested_at = Time.current if declaration.sender_attestation
    declaration.save!

    validation = validate_declaration!(declaration)

    { declaration: declaration, validation: validation }
  end
end

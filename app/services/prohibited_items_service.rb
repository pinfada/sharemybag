class ProhibitedItemsService
  class ProhibitedItemDetectedError < StandardError; end

  # IATA Dangerous Goods Regulation (DGR) keywords
  IATA_PROHIBITED_KEYWORDS = {
    explosives: %w[explosive dynamite detonator firework firecracker ammunition cartridge grenade mine bomb TNT gunpowder pyrotechnic],
    gases: %w[aerosol butane propane compressed_gas oxygen acetylene fire_extinguisher],
    flammable_liquids: %w[gasoline petrol diesel kerosene acetone turpentine alcohol paint_thinner lighter_fluid],
    flammable_solids: %w[matches magnesium phosphorus],
    oxidizers: %w[bleach peroxide fertilizer nitrate],
    toxic: %w[pesticide insecticide rat_poison cyanide arsenic mercury],
    radioactive: %w[radioactive uranium plutonium],
    corrosives: %w[acid battery sulfuric hydrochloric caustic_soda],
    miscellaneous: %w[lithium_battery dry_ice asbestos magnetized_material],
    weapons: %w[gun pistol rifle shotgun weapon knife blade sword taser pepper_spray],
    drugs: %w[cocaine heroin cannabis marijuana drug narcotic opium methamphetamine],
    counterfeit: %w[counterfeit fake replica imitation],
    currency: %w[currency banknote cash],
    biological: %w[biological specimen blood tissue organ],
    protected_species: %w[ivory horn tusk endangered fur animal_parts]
  }.freeze

  # Maximum amounts allowed in hold baggage (kg)
  HOLD_LIMITS = {
    "aerosol" => 2.0,
    "alcohol" => 5.0,
    "perfume" => 0.5,
    "lighter_fluid" => 0.0,
    "lithium_battery" => 0.0 # Must be in cabin
  }.freeze

  attr_reader :shipping_request

  def initialize(shipping_request)
    @shipping_request = shipping_request
  end

  def screen_contents!
    results = { passed: true, warnings: [], blocked_items: [], requires_declaration: [] }

    # Screen description
    description = [
      shipping_request.description,
      shipping_request.title,
      shipping_request.special_instructions
    ].compact.join(" ")

    IATA_PROHIBITED_KEYWORDS.each do |category, keywords|
      keywords.each do |keyword|
        if description.downcase.include?(keyword.tr("_", " "))
          if universally_prohibited?(category)
            results[:passed] = false
            results[:blocked_items] << { keyword: keyword, category: category.to_s, reason: "Prohibited by IATA DGR" }
          else
            results[:warnings] << { keyword: keyword, category: category.to_s, reason: "May require special declaration" }
            results[:requires_declaration] << keyword
          end
        end
      end
    end

    # Screen declared contents if present
    if shipping_request.declared_contents.present?
      shipping_request.declared_contents.each do |item|
        item_desc = item.is_a?(Hash) ? item["description"] : item.to_s
        db_matches = ProhibitedItem.check_item(item_desc,
          country: shipping_request.arrival_country)
        db_matches.each do |match|
          if match.universally_prohibited?
            results[:passed] = false
            results[:blocked_items] << { item: item_desc, matched: match.name, un_number: match.un_number }
          end
        end
      end
    end

    # Check airline-specific restrictions if flight is known
    check_airline_restrictions!(results) if airline_code.present?

    results
  end

  def universally_prohibited?(category)
    %i[explosives radioactive toxic weapons drugs biological protected_species].include?(category)
  end

  private

  def airline_code
    bid = shipping_request.accepted_bid
    return nil unless bid
    flight_number = bid.flight_number
    return nil unless flight_number.present?
    flight_number[0..1].upcase
  end

  def check_airline_restrictions!(results)
    policy = AirlinePolicy.find_by(airline_code: airline_code, active: true)
    return unless policy

    unless policy.allows_third_party?
      results[:passed] = false
      results[:blocked_items] << {
        reason: "Airline #{policy.airline_name} does not allow third-party items in baggage",
        airline: airline_code
      }
    end

    unless policy.weight_compliant?(shipping_request.weight_kg)
      results[:warnings] << {
        reason: "Package weight #{shipping_request.weight_kg}kg exceeds airline limit of #{policy.max_checked_weight_kg}kg",
        airline: airline_code
      }
    end

    if shipping_request.length_cm && shipping_request.width_cm && shipping_request.height_cm
      unless policy.dimensions_compliant?(shipping_request.length_cm, shipping_request.width_cm, shipping_request.height_cm)
        results[:warnings] << {
          reason: "Package dimensions exceed airline maximum",
          airline: airline_code
        }
      end
    end
  end
end

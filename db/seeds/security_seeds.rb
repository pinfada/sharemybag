# Seed data for IATA Dangerous Goods and Prohibited Items
# Reference: IATA DGR 65th Edition (2024)

ProhibitedItem.destroy_all if Rails.env.development?

prohibited_items = [
  # Class 1 - Explosives
  { name: "Explosives", name_fr: "Explosifs", category: "iata_class_1", iata_class: "1", description: "Any explosive substance or article", description_fr: "Toute substance ou article explosif", universally_prohibited: true },
  { name: "Fireworks", name_fr: "Feux d'artifice", category: "iata_class_1", iata_class: "1", un_number: "UN0336", description: "Pyrotechnic devices", universally_prohibited: true },
  { name: "Ammunition", name_fr: "Munitions", category: "iata_class_1", iata_class: "1", un_number: "UN0012", description: "Cartridges, bullets", universally_prohibited: true },
  { name: "Detonators", name_fr: "Détonateurs", category: "iata_class_1", iata_class: "1", un_number: "UN0029", universally_prohibited: true },

  # Class 2 - Gases
  { name: "Compressed gases", name_fr: "Gaz comprimés", category: "iata_class_2", iata_class: "2", description: "Butane, propane, oxygen cylinders", universally_prohibited: true },
  { name: "Aerosols (flammable)", name_fr: "Aérosols inflammables", category: "iata_class_2", iata_class: "2", un_number: "UN1950", description: "Flammable aerosol cans", hold_allowed: true, max_quantity: "500ml", universally_prohibited: false, requires_declaration: true },
  { name: "Fire extinguishers", name_fr: "Extincteurs", category: "iata_class_2", iata_class: "2", universally_prohibited: true },

  # Class 3 - Flammable Liquids
  { name: "Gasoline/Petrol", name_fr: "Essence", category: "iata_class_3", iata_class: "3", un_number: "UN1203", universally_prohibited: true },
  { name: "Lighter fluid", name_fr: "Liquide pour briquet", category: "iata_class_3", iata_class: "3", un_number: "UN1226", universally_prohibited: true },
  { name: "Paint/Solvents", name_fr: "Peinture/Solvants", category: "iata_class_3", iata_class: "3", universally_prohibited: true },
  { name: "Alcohol > 70%", name_fr: "Alcool > 70%", category: "iata_class_3", iata_class: "3", hold_allowed: true, max_quantity: "5L", universally_prohibited: false, requires_declaration: true },

  # Class 4 - Flammable Solids
  { name: "Matches (strike anywhere)", name_fr: "Allumettes", category: "iata_class_4", iata_class: "4", un_number: "UN1331", universally_prohibited: true },

  # Class 5 - Oxidizers
  { name: "Bleach/Peroxide", name_fr: "Eau de javel/Peroxyde", category: "iata_class_5", iata_class: "5", universally_prohibited: true },

  # Class 6 - Toxic Substances
  { name: "Pesticides", name_fr: "Pesticides", category: "iata_class_6", iata_class: "6", universally_prohibited: true },
  { name: "Poisons", name_fr: "Poisons", category: "iata_class_6", iata_class: "6", universally_prohibited: true },
  { name: "Infectious substances", name_fr: "Substances infectieuses", category: "iata_class_6", iata_class: "6", un_number: "UN2814", universally_prohibited: true },

  # Class 7 - Radioactive Material
  { name: "Radioactive material", name_fr: "Matériel radioactif", category: "iata_class_7", iata_class: "7", universally_prohibited: true },

  # Class 8 - Corrosives
  { name: "Acids", name_fr: "Acides", category: "iata_class_8", iata_class: "8", universally_prohibited: true },
  { name: "Car batteries", name_fr: "Batteries de voiture", category: "iata_class_8", iata_class: "8", un_number: "UN2794", universally_prohibited: true },

  # Class 9 - Miscellaneous
  { name: "Lithium batteries (spare, > 100Wh)", name_fr: "Batteries lithium (> 100Wh)", category: "iata_class_9", iata_class: "9", un_number: "UN3480", description: "Spare lithium batteries over 100Wh", universally_prohibited: false, cabin_allowed: true, hold_allowed: false, requires_declaration: true },
  { name: "Dry ice", name_fr: "Glace sèche", category: "iata_class_9", iata_class: "9", un_number: "UN1845", hold_allowed: true, max_quantity: "2.5kg", universally_prohibited: false, requires_declaration: true },
  { name: "Magnetized material", name_fr: "Matériel magnétisé", category: "iata_class_9", iata_class: "9", universally_prohibited: false, requires_declaration: true },

  # Weapons & Ammunition
  { name: "Firearms", name_fr: "Armes à feu", category: "weapons_ammunition", description: "Guns, pistols, rifles", universally_prohibited: true },
  { name: "Knives/Blades", name_fr: "Couteaux/Lames", category: "weapons_ammunition", description: "Blades over 6cm", cabin_allowed: false, hold_allowed: true, universally_prohibited: false },
  { name: "Tasers/Stun guns", name_fr: "Tasers", category: "weapons_ammunition", universally_prohibited: true },
  { name: "Pepper spray", name_fr: "Spray au poivre", category: "weapons_ammunition", universally_prohibited: true },

  # Controlled Substances
  { name: "Narcotics", name_fr: "Stupéfiants", category: "controlled_substances", universally_prohibited: true },
  { name: "Cannabis products", name_fr: "Produits de cannabis", category: "controlled_substances", universally_prohibited: true },

  # Counterfeit Goods
  { name: "Counterfeit goods", name_fr: "Contrefaçons", category: "counterfeit_goods", universally_prohibited: true },

  # Currency Restrictions
  { name: "Cash > €10,000", name_fr: "Espèces > 10 000€", category: "currency_restrictions", description: "Undeclared cash exceeding threshold", universally_prohibited: false, requires_declaration: true },

  # Customs Restricted (country-specific)
  { name: "Fresh meat", name_fr: "Viande fraîche", category: "customs_restricted", universally_prohibited: false, restricted_countries: %w[US AU NZ JP], requires_declaration: true },
  { name: "Dairy products", name_fr: "Produits laitiers", category: "customs_restricted", universally_prohibited: false, restricted_countries: %w[US AU NZ], requires_declaration: true },
  { name: "Seeds and plants", name_fr: "Graines et plantes", category: "customs_restricted", universally_prohibited: false, restricted_countries: %w[US AU NZ JP CA], requires_declaration: true },
  { name: "Ivory products", name_fr: "Produits en ivoire", category: "customs_restricted", description: "CITES protected", universally_prohibited: true },
  { name: "Endangered species products", name_fr: "Produits d'espèces menacées", category: "customs_restricted", description: "CITES protected", universally_prohibited: true },
]

prohibited_items.each do |attrs|
  ProhibitedItem.find_or_create_by!(name: attrs[:name]) do |item|
    attrs.each { |key, value| item.send("#{key}=", value) }
  end
end

puts "Created #{ProhibitedItem.count} prohibited items"

# Seed Airline Policies
AirlinePolicy.destroy_all if Rails.env.development?

airlines = [
  { airline_code: "AF", airline_name: "Air France", max_checked_weight_kg: 23, max_carry_on_weight_kg: 12, max_single_item_weight_kg: 32, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "BA", airline_name: "British Airways", max_checked_weight_kg: 23, max_carry_on_weight_kg: 23, max_single_item_weight_kg: 32, max_total_dimensions_cm: 190, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "LH", airline_name: "Lufthansa", max_checked_weight_kg: 23, max_carry_on_weight_kg: 8, max_single_item_weight_kg: 32, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "AA", airline_name: "American Airlines", max_checked_weight_kg: 23, max_carry_on_weight_kg: 22, max_single_item_weight_kg: 32, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "DL", airline_name: "Delta Air Lines", max_checked_weight_kg: 23, max_carry_on_weight_kg: 22, max_single_item_weight_kg: 32, max_total_dimensions_cm: 157, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "UA", airline_name: "United Airlines", max_checked_weight_kg: 23, max_carry_on_weight_kg: 22, max_single_item_weight_kg: 32, max_total_dimensions_cm: 157, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "EK", airline_name: "Emirates", max_checked_weight_kg: 30, max_carry_on_weight_kg: 7, max_single_item_weight_kg: 32, max_total_dimensions_cm: 300, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "QR", airline_name: "Qatar Airways", max_checked_weight_kg: 30, max_carry_on_weight_kg: 7, max_single_item_weight_kg: 32, max_total_dimensions_cm: 300, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "TK", airline_name: "Turkish Airlines", max_checked_weight_kg: 23, max_carry_on_weight_kg: 8, max_single_item_weight_kg: 32, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "ET", airline_name: "Ethiopian Airlines", max_checked_weight_kg: 23, max_carry_on_weight_kg: 7, max_single_item_weight_kg: 32, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "AT", airline_name: "Royal Air Maroc", max_checked_weight_kg: 23, max_carry_on_weight_kg: 10, max_single_item_weight_kg: 32, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "SA", airline_name: "South African Airways", max_checked_weight_kg: 23, max_carry_on_weight_kg: 8, max_single_item_weight_kg: 32, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "KQ", airline_name: "Kenya Airways", max_checked_weight_kg: 23, max_carry_on_weight_kg: 7, max_single_item_weight_kg: 32, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "W3", airline_name: "Arik Air", max_checked_weight_kg: 23, max_carry_on_weight_kg: 7, max_single_item_weight_kg: 23, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
  { airline_code: "HF", airline_name: "Air Côte d'Ivoire", max_checked_weight_kg: 23, max_carry_on_weight_kg: 7, max_single_item_weight_kg: 23, max_total_dimensions_cm: 158, allows_third_party_items: true, liability_policy: "limited" },
]

airlines.each do |attrs|
  AirlinePolicy.find_or_create_by!(airline_code: attrs[:airline_code]) do |policy|
    attrs.each { |key, value| policy.send("#{key}=", value) }
  end
end

puts "Created #{AirlinePolicy.count} airline policies"

class ProhibitedItem < ActiveRecord::Base
  # IATA Dangerous Goods Classes
  IATA_CLASSES = {
    "1" => "Explosives",
    "2" => "Gases",
    "3" => "Flammable Liquids",
    "4" => "Flammable Solids",
    "5" => "Oxidizing Substances & Organic Peroxides",
    "6" => "Toxic & Infectious Substances",
    "7" => "Radioactive Material",
    "8" => "Corrosives",
    "9" => "Miscellaneous Dangerous Goods"
  }.freeze

  CATEGORIES = %w[
    iata_class_1 iata_class_2 iata_class_3 iata_class_4 iata_class_5
    iata_class_6 iata_class_7 iata_class_8 iata_class_9
    customs_restricted airline_specific weapons_ammunition
    controlled_substances counterfeit_goods currency_restrictions
  ].freeze

  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :active, -> { where(active: true) }
  scope :universal, -> { where(universally_prohibited: true) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :by_iata_class, ->(cls) { where(iata_class: cls.to_s) }
  scope :for_country, ->(country) {
    where("restricted_countries = '{}' OR ? = ANY(restricted_countries)", country)
  }
  scope :for_airline, ->(airline_code) {
    where("restricted_airlines = '{}' OR ? = ANY(restricted_airlines)", airline_code)
  }

  def self.check_item(description, country: nil, airline_code: nil)
    items = active
    items = items.for_country(country) if country
    items = items.for_airline(airline_code) if airline_code

    matched = items.select do |item|
      keywords = [item.name, item.name_fr, item.description, item.description_fr].compact
      keywords.any? { |kw| description.downcase.include?(kw.downcase) }
    end

    matched
  end
end

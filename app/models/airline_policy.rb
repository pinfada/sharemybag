class AirlinePolicy < ActiveRecord::Base
  validates :airline_code, presence: true, uniqueness: true, length: { is: 2 }
  validates :airline_name, presence: true

  scope :active, -> { where(active: true) }

  def weight_compliant?(weight_kg)
    return true unless max_checked_weight_kg
    weight_kg <= max_checked_weight_kg
  end

  def dimensions_compliant?(length_cm, width_cm, height_cm)
    return true unless max_total_dimensions_cm
    total = (length_cm || 0) + (width_cm || 0) + (height_cm || 0)
    total <= max_total_dimensions_cm
  end

  def item_allowed?(item_description)
    return true if prohibited_items.blank?
    prohibited_items.none? { |p| item_description.downcase.include?(p.downcase) }
  end

  def allows_third_party?
    allows_third_party_items
  end
end

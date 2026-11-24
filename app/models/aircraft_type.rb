class AircraftType < ApplicationRecord
  has_many :flights, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 24 }
  validates :aircraft_name, presence: true, length: { maximum: 80 }
  validates :manufacturer, presence: true, length: { maximum: 60 }
  validates :seat_capacity, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 900 }
  validates :default_baggage_kg_per_pax, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 50 }
  validates :max_baggage_payload_kg, presence: true, numericality: { greater_than: 0 }
  validates :fuel_burn_rate_per_kg_hour, presence: true, numericality: { greater_than: 0, less_than: 0.5 }

  def standard_fleet_baggage_envelope_kg
    (seat_capacity * default_baggage_kg_per_pax.to_f).round(1)
  end
end

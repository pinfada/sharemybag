class Coordonnee < ActiveRecord::Base
  belongs_to :airport
  geocoded_by :titre
  after_validation :geocode, :if => :titre_changed? 
end

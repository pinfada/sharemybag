class Bagage < ActiveRecord::Base
	belongs_to :user
	belongs_to :booking
	has_many :paquets
	validates :prix,  presence: true
	validates :poids,  presence: true
	validates :longueur,  presence: true
	validates :largeur,  presence: true
	validates :hauteur,  presence: true
end

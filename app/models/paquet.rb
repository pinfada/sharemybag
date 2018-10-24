class Paquet < ActiveRecord::Base
  belongs_to :user
  belongs_to :bagage
end

FactoryBot.define do
  factory :bagage do
    poids { 1 }
    prix { 1 }
    longueur { 1 }
    largeur { 1 }
    hauteur { 1 }
    booking { nil }
    user { nil }
  end
end

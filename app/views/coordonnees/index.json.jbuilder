json.array!(@coordonnees) do |coordonnee|
  json.extract! coordonnee, :id
  json.url coordonnee_url(coordonnee, format: :json)
end

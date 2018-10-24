json.array!(@paquets) do |paquet|
  json.extract! paquet, :id
  json.url paquet_url(paquet, format: :json)
end

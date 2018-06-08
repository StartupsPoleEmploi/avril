defmodule Vae.PlacesClient.Algolia do
   @behaviour Vae.PlacesClient

   @url_places "https://status.algolia.com/1/usage/total_read_operations/period/last_day/places"

   def get(_credentials) do
     headers = ["X-Algolia-API-Key: #{}", "X-Algolia-Application-Id: #{}"]
     HTTPoison.get(@url_places, headers)
   end
end

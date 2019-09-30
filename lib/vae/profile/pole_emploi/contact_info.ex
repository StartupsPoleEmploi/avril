defmodule Vae.Profile.ContactInfo do
  @path "https://api.emploi-store.fr/partenaire/peconnect-coordonnees/v1/coordonnees"

  def execute(token) do
    call(token)
    |> format()
  end

  def call(token) do
    Vae.OAuth.get(token, @path)
  end

  def format(%OAuth2.Response{body: body}) do
    Vae.User.coordonnees_api_map(body)
  end

  def is_data_missing(contact_info), do: is_nil(contact_info.postal_code)
end

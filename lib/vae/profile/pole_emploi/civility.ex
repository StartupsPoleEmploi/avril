defmodule Vae.Profile.Civility do
  @path "https://api.emploi-store.fr/partenaire/peconnect-datenaissance/v1/etat-civil"

  def execute(token) do
    call(token)
    |> format()
  end

  def call(token) do
    Vae.OAuth.get(token, @path)
  end

  def format(%OAuth2.Response{body: body}) do
    %{
      birthday: Timex.parse!(body["dateDeNaissance"], "{ISO:Extended}")
    }
  end

  def is_data_missing(user), do: is_nil(user.postal_code)
end

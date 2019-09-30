defmodule Vae.Profile.Experiences do
  @path "https://api.emploi-store.fr/partenaire/peconnect-experiences/v1/experiences"

  def execute(token) do
    call(token)
    |> format()
  end

  def call(token) do
    Vae.OAuth.get(token, @path)
  end

  def format(%OAuth2.Response{body: body}) do
    %{
      experiences: Enum.map(body, &Vae.Experience.experiences_api_map/1)
    }
  end

  def is_data_missing(user), do: is_nil(user.birthday)
end

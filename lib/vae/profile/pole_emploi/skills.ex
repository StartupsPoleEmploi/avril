defmodule Vae.Profile.Skills do
  @path "https://api.emploi-store.fr/partenaire/peconnect-competences/v2/competences"

  def(execute(token)) do
    call(token)
    |> format()
  end

  def call(token) do
    Vae.OAuth.get(token, @path)
  end

  def format(%OAuth2.Response{body: body}) do
    %{
      skills: Enum.map(body, &Vae.Skill.competences_api_map/1)
    }
  end

  def is_data_missing(user) do
    Enum.empty?(user.skills)
  end
end

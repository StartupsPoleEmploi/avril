defmodule Vae.PoleEmploi.Mappers.ExperiencesMapper do
  def map(%OAuth2.Response{body: body}) do
    %{
      experiences: Enum.map(body, &to_experience/1)
    }
  end

  def to_experience(api_fields) do
    %{
      company: Vae.String.titleize(api_fields["entreprise"]),
      start_date: Vae.Date.format(api_fields["date"]["debut"]),
      end_date: Vae.Date.format(api_fields["date"]["fin"]),
      is_current_job: api_fields["enPoste"],
      is_abroad: api_fields["etranger"],
      label: Vae.String.titleize(api_fields["intitule"]),
      duration: api_fields["duree"]
    }
  end

  def is_missing?(map), do: is_nil(map[:experiences]) || Enum.empty?(map[:experiences])
end

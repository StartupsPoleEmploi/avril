defmodule Vae.Experience do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:company, :string)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:is_current_job, :boolean)
    field(:is_abroad, :boolean)
    field(:label, :string)
    field(:duration, :integer)
  end

  @fields ~w(company start_date end_date is_abroad label duration)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end

  def unique_key(experience) do
    "#{experience.company}-#{experience.label}-#{Timex.format!(experience.start_date, "{YYYY}{0M}{0D}")}-#{if experience.end_date, do: Timex.format!(experience.end_date, "{YYYY}{0M}{0D}"), else: ""}"
  end

  def experiences_api_map(api_fields) do
    %__MODULE__{
      company: Vae.String.titleize(api_fields["entreprise"]),
      start_date: Vae.Date.format(api_fields["date"]["debut"]),
      end_date: Vae.Date.format(api_fields["date"]["fin"]),
      is_current_job: api_fields["enPoste"],
      is_abroad: api_fields["etranger"],
      label: Vae.String.titleize(api_fields["intitule"]),
      duration: api_fields["duree"]
    }
  end
end
defmodule Vae.Booklet.CurrentSituation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    # Employee, inactive, job_seeker, volunteer, electoral_term
    field(:status, :string)

    # employee
    field(:employment_type, :string)

    # job_seeker
    field(:register_to_pole_emploi, :boolean)
    field(:register_to_pole_emploi_since, :date)
    field(:compensation_type, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :status,
      :employment_type,
      :register_to_pole_emploi,
      :register_to_pole_emploi_since,
      :compensation_type
    ])
  end

  def current_situation_label(status) do
    case status do
      "working" -> "En situation d'emploi"
      "inactive" -> "En inactivité"
      "jobseeking" -> "En recherche d'emploi"
      "volontary" -> "Volontaire"
      "election" -> "Mandat électoral"
      "unknown" -> "Inconnu"
    end
  end

end

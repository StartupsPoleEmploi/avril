defmodule Vae.ProvenExperience do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:start_date, :date)
    field(:end_date, :date)
    field(:label, :string)
    field(:contract_type, :string)
    field(:is_manager, :boolean)
    field(:work_duration, :integer)
    field(:duration, :integer)
    field(:company_ape, :string)
    field(:company_name, :string)
    field(:company_state_owned, :boolean)
    field(:company_uid, :string)
  end

  @fields ~w(start_date end_date label contract_type is_manager work_duration duration company_uid company_ape company_name company_state_owned)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end

  def experiencesprofessionellesdeclareesparlemployeur_api_map(api_fields) do
    %{
      start_date: Vae.Date.format(api_fields["dateDebut"]),
      end_date: Vae.Date.format(api_fields["dateFin"]),
      duration: api_fields["dureeContrat"],
      label: Vae.String.titleize(api_fields["intitulePoste"]),
      contract_type: api_fields["natureContrat"],
      is_manager: api_fields["niveauQualification"] == "Cadre",
      duration: api_fields["quantiteTravail"],
      company_ape: api_fields["entreprise"]["codeApe"],
      company_name: Vae.String.titleize(api_fields["entreprise"]["nom"]),
      company_category: api_fields["entreprise"]["regime"],
      company_state_owned: api_fields["entreprise"]["secteur"] == "Public",
      company_uid: api_fields["entreprise"]["siret"]
    }
  end
end
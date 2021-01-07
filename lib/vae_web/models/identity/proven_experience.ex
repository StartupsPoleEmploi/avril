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
    field(:company_category, :string)
    field(:company_state_owned, :boolean)
    field(:company_uid, :string)
  end

  @fields ~w(start_date end_date label contract_type is_manager work_duration duration company_uid company_ape company_name company_state_owned)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end

  def unique_key(experience) do
    "#{experience.company_uid}-#{experience.label}-#{
      Vae.Date.format_for_unique_key(experience.start_date)
    }-#{Vae.Date.format_for_unique_key(experience.end_date)}"
  end
end

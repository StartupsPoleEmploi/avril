defmodule Vae.Skill do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:code, :integer)
    field(:label, :string)
    field(:type, :string)
    field(:level_code, :integer)
    field(:level_label, :string)
  end

  @fields ~w(code label type level_label level_code)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end

  def unique_key(skill) do
    skill.code
  end

  def competences_api_map(api_fields) do
    %__MODULE__{
      code: String.to_integer(api_fields["code"] || "0"),
      label: api_fields["libelle"],
      type: api_fields["type"],
      level_code: String.to_integer(api_fields["niveau"]["code"] || "0"),
      level_label: api_fields["niveau"]["libelle"]
    }
  end
end

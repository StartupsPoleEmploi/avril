defmodule Vae.Skill do
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
end

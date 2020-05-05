defmodule Vae.Booklet.Address do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:city, :string)
    field(:county, :string)
    field(:country, :string)
    field(:lat, :float)
    field(:lng, :float)
    field(:street, :string)
    field(:postal_code, :string)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:city, :county, :country, :lat, :lng, :street, :postal_code])
  end

  @required_fields_for_submission ~w(
    postal_code
    city
    country
  )a
  def validate_required_fields(struct, params \\ %{}) do
    struct
    |> cast(params, [])
    |> validate_required(@required_fields_for_submission)
  end
end

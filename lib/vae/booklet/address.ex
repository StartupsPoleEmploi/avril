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

  def address_city(%{}), do: ""

  def address_city(%__MODULE__{} = address) do
    [
      Vae.Enum.join_keep_nil([address.postal_code, address.city], " "),
      address.country
    ]
    |> Vae.Enum.join_keep_nil(", ")
  end

  def address(%__MODULE__{} = address) do
    [
      address_street(address),
      address_city(address)
    ]
    |> Vae.Enum.join_keep_nil("\n")
  end

  def address_street(%{}), do: ""
  def address_street(address), do: address.street
end

defmodule Vae.Booklet.Address do
  use Ecto.Schema
  use StructAccess

  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder

  alias __MODULE__

  embedded_schema do
    field(:city, :string)
    field(:county, :string)
    field(:country, :string)
    field(:country_code, :string)
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


  def address_city(%{postal_code: postal_code, city: city, country: country}) do
    [
      Vae.Enum.join_keep_nil([postal_code, city], " "),
      country
    ]
    |> Vae.Enum.join_keep_nil(", ")
  end
  def address_city(_), do: ""

  def address(%Address{} = address, new_line_representation \\ "\n") do
    [
      address.street,
      address_city(address)
    ] |> Enum.filter(&(!is_nil(&1))) |> Enum.join(new_line_representation)
  end
end

defimpl Phoenix.HTML.Safe, for: Vae.Booklet.Address do
  def to_iodata(address) do
    address
    |> Vae.Booklet.Address.address("<br/>")
    |> Phoenix.HTML.raw()
    |> Phoenix.HTML.Safe.to_iodata()
  end
end

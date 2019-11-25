defmodule Vae.Booklet.Civility do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:gender, :string)
    field(:birthday, :date)
    field(:birth_place, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:usage_name, :string)
    field(:email, :string)
    field(:home_phone, :string)
    field(:mobile_phone, :string)
    field(:street_address, :string)
    field(:postal_code, :string)
    field(:city, :string)
    field(:country, :string)
  end

  @fields ~w(
    gender
    birthday
    birth_place
    first_name
    last_name
    usage_name
    email
    home_phone
    mobile_phone
    street_address
    postal_code
    city
    country
  )a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end
end

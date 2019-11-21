defmodule Vae.Booklet.Civility do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:gender, :string)
    field(:birthday, :date)
    field(:birthplace, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:usage_name, :string)
    field(:email, :string)
    field(:home_phone, :string)
    field(:mobile_number, :string)
    field(:street_address, :string)
    field(:postal_code, :string)
    field(:city, :string)
    field(:country, :string)
  end
end

defmodule Vae.Booklet.Address do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:city, :string)
    field(:country, :string)
    field(:domTom, :string)
    field(:lat, :float)
    field(:lng, :float)
    field(:street, :string)
    field(:postal_code, :string)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:city, :country, :domTom, :lat, :lng, :street, :postal_code])
  end
end

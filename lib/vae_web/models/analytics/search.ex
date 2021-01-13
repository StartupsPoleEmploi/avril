defmodule Vae.Search do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:rome_code, :string)
    field(:profession, :string)
    field(:geolocation_text, :string)
    field(:lat, :string)
    field(:lng, :string)
  end

  @fields ~w(rome_code profession geolocation_text lat lng)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
  end
end
defmodule Vae.Meeting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:academy_id, :integer)
    field(:address, :string)
    field(:city, :string)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
    field(:meeting_id, :string)
    field(:place, :string)
    field(:postal_code, :string)
    field(:remaining_places, :integer)
    field(:target, :string)
    field(:geolocation, :map)
  end

  @fields ~w(academy_id meeting_id place address postal_code geolocation target start_date end_date)a

  def changeset(module, params) do
    module
    |> cast(params, @fields)
    |> validate_required([
      :academy_id,
      :meeting_id,
      :place,
      :address,
      :postal_code,
      :start_date,
      :end_date
    ])
  end

  defimpl ExAdmin.Render, for: __MODULE__ do
    def to_string(data) do
      if data, do: ExAdmin.Render.to_string(data.start_date)
    end
  end
end

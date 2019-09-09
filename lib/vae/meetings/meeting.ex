defmodule Vae.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset
  use Xain

  @primary_key false
  embedded_schema do
    field(:academy_id, :integer)
    field(:meeting_id, :integer)
    field(:place, :string)
    field(:address, :string)
    field(:postal_code, :string)
    field(:geolocation, :map)
    field(:target, :string)
    field(:remaining_places, :integer)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
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
      markup do
        pre(Jason.encode!(Map.from_struct(data), pretty: true))
      end
    end
  end
end

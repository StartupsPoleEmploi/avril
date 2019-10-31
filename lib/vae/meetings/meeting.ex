defmodule Vae.Meetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset
  use Xain

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:academy_id, :integer)
    field(:meeting_id, :integer)
    field(:meeting_id2, :string)
    field(:place, :string)
    field(:address, :string)
    field(:postal_code, :string)
    field(:city, :string)
    field(:geolocation, :map)
    field(:target, :string)
    field(:remaining_places, :integer)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
  end

  @fields ~w(name academy_id meeting_id meeting_id2 place address postal_code geolocation target start_date end_date)a

  def changeset(module, params) do
    module
    |> cast(params, @fields)
    |> validate_required([
      :name,
      :academy_id,
      :meeting_id,
      :place,
      :address,
      :postal_code,
      :start_date,
      :end_date
    ])
    |> fill_meeting_id2(params[:meeting_id])
  end

  def fill_meeting_id2(changeset, meeting_id) do
    put_change(changeset, :meeting_id2, Integer.to_string(meeting_id))
  end

  defimpl ExAdmin.Render, for: __MODULE__ do
    def to_string(data) do
      markup do
        pre(Jason.encode!(Map.from_struct(data), pretty: true))
      end
    end
  end
end

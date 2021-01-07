defmodule Vae.Meeting do
  use VaeWeb, :model

  alias __MODULE__
  alias Vae.Places.Ban

  schema "meetings" do
    field(:source, :string)
    field(:geom, Geo.PostGIS.Geometry)
    embeds_one(:data, MeetingData, on_replace: :update) do
      @derive Jason.Encoder
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

      def changeset(module, params) do
        module
        |> cast(params, ~w(academy_id meeting_id place address postal_code geolocation target start_date end_date)a)
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
    end

    timestamps()
  end

  def changeset(%Meeting{} = meeting, params \\ %{}) do
    meeting
    |> cast(params, ~w(source data)a)
    |> add_geometry()
    |> validate_required([
      :source,
      :geom,
      :data
    ])
  end

  def add_geometry(%Ecto.Changeset{} = changeset) do
    if get_change(changeset, :data) do
      result =
        Ban.get_geoloc_from_address(get_field(changeset, :data).address) ||
        Ban.get_geoloc_from_postal_code(get_field(changeset, :data).postal_code)

      put_change(changeset, :geom, %Geo.Point{coordinates: Ban.get_field(result, :lng_lat)})
    else
      changeset
    end
  end

  def get_by_meeting_id(source, meeting_id) do
    from(m in Meeting)
      |> where([m], m.source == ^source)
      |> where([_q], fragment("(data->>'meeting_id' = ?)", ^meeting_id))
      |> Repo.one()
  end

  defimpl ExAdmin.Render, for: __MODULE__ do
    def to_string(data) do
      if data, do: ExAdmin.Render.to_string(data.start_date)
    end
  end
end

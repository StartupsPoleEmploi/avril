defmodule Vae.Meeting do
  use VaeWeb, :model

  import Geo.PostGIS

  alias __MODULE__
  alias Vae.{Delegate, Places.Ban}

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
        |> cast(params, ~w(academy_id meeting_id place city address postal_code target start_date end_date)a)
        |> validate_required([
          :meeting_id,
          :place,
          :start_date
        ])
      end
    end

    timestamps()
  end

  def changeset(%Meeting{} = meeting, params \\ %{}) do
    meeting
    |> cast(params, ~w(source)a)
    |> cast_embed(:data)
    |> add_geometry()
    |> validate_required([:source, :data])
  end

  def add_geometry(%Ecto.Changeset{} = changeset, opts \\ []) do
    changeset_needs_to_update_geometry = with(
      data_change when not is_nil(data_change) <- get_change(changeset, :data),
      address_change when not is_nil(address_change) <-
        get_change(data_change, :address) ||
        get_change(data_change, :postal_code) ||
        get_change(data_change, :city)
    ) do
      true
    else
      _ -> false
    end

    with(
      true <- opts[:force] || changeset_needs_to_update_geometry,
      %{address: address, postal_code: postal_code, city: city} <- get_field(changeset, :data),
      ban_result <-
        Ban.get_geoloc_from_address("#{address} #{postal_code} #{city}") ||
        Ban.get_geoloc_from_postal_code(postal_code),
      coordinates when not is_nil(coordinates) <- Ban.get_field(ban_result, :lng_lat)
    ) do
      put_change(changeset, :geom, %Geo.Point{coordinates: coordinates})
    else
      _ -> changeset
    end
  end

  def get_by_meeting_id(source, meeting_id) do
    from(m in Meeting)
      |> where([m], m.source == ^"#{source}")
      |> where([_q], fragment("(data->>'meeting_id' = ?)", ^meeting_id))
      |> Repo.one()
  end

  def find_future_meetings_for_delegate(%Delegate{academy_id: academy_id, geom: geom} = d, radius \\ 50_000) do
    sql_formatted_date = Timex.format!(Date.utc_today(), "%Y-%m-%d", :strftime)

    from(m in Meeting)
      |> where([m], m.source == ^"#{Delegate.get_meeting_source(d)}")
      |> Vae.Maybe.if(not is_nil(academy_id), fn q -> where(q, [_q], fragment("data->>'academy_id' = ?", ^academy_id)) end)
      |> where([_q], fragment("TO_DATE(data->>'start_date', 'YYYY-MM-DD') > TO_DATE(?, 'YYYY-MM-DD')", ^sql_formatted_date))
      |> where([m], st_dwithin_in_meters(m.geom, ^geom, ^radius))
      |> Repo.all()
  end

  defimpl ExAdmin.Render, for: __MODULE__ do
    def to_string(data) do
      if data, do: ExAdmin.Render.to_string(data.start_date)
    end
  end
end

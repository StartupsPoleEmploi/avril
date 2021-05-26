defmodule Vae.Meeting do
  use VaeWeb, :model
  require Logger

  import Geo.PostGIS

  alias __MODULE__
  alias Vae.{Delegate, Places.Ban, UserApplication}

  schema "meetings" do
    field(:source, :string)
    field(:deleted_at, :utc_datetime)
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

    has_many(:applications, UserApplication, foreign_key: :meeting_id)

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

  def source_string(source) do
    case source do
      :france_vae -> "France VAE"
      :afpa -> "AFPA"
      other -> other
    end
  end

  def get_by_meeting_id(source, meeting_id) do
    from(m in Meeting)
      |> where([m], m.source == ^"#{source}")
      |> where([_q], fragment("(data->>'meeting_id' = ?)", ^meeting_id))
      |> Repo.one()
  end

  def find_future_meetings_for_delegate(%Delegate{academy_id: academy_id, geom: geom} = d, radius \\ 200_000) do

    from(m in Meeting)
      |> where([m], m.source == ^"#{Delegate.get_meeting_source(d)}")
      |> Vae.Maybe.if(not is_nil(academy_id), fn q -> where(q, [_q], fragment("data->>'academy_id' = ?", ^academy_id)) end)
      |> where_future_start_date()
      |> where([m], st_dwithin_in_meters(m.geom, ^geom, ^radius) or is_nil(m.geom))
      |> Repo.all()
  end

  def mark_as_deleted_and_inform(%Meeting{} = meeting) do
    %Meeting{applications: applications} = meeting |> Repo.preload([applications: :user])

    {:ok, _} = Enum.reduce(applications, {:ok, nil}, fn application, {:ok, _} ->
      application
      |> VaeWeb.ApplicationEmail.user_meeting_cancelled()
      |> VaeWeb.Mailer.send()
    end)

    {:ok, _} = meeting
    |> change(%{deleted_at: DateTime.truncate(DateTime.utc_now(), :second)})
    |> Repo.update()

    meeting
  end

  def mark_elders_as_deleted(source, update_started_at) do
    Meeting
    |> where([m], m.source == ^"#{source}")
    |> where([m], is_nil(m.deleted_at))
    |> where_future_start_date()
    |> where([m], m.updated_at < ^DateTime.truncate(update_started_at, :second))
    |> Repo.all()
    |> Enum.map(&mark_as_deleted_and_inform(&1))
  end

  defp where_future_start_date(query) do
    sql_formatted_date = Timex.format!(Date.utc_today(), "%Y-%m-%d", :strftime)
    query
    |> where([_q], fragment("TO_DATE(data->>'start_date', 'YYYY-MM-DD') > TO_DATE(?, 'YYYY-MM-DD')", ^sql_formatted_date))
  end

  defimpl ExAdmin.Render, for: __MODULE__ do
    def to_string(%Vae.Meeting{data: %{start_date: start_date}}), do:
      ExAdmin.Render.to_string(start_date)
  end
end

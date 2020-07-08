defmodule Vae.Meetings.FranceVae.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.FranceVae
  alias Vae.Meeting

  @name :france_vae

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  @impl true
  def init(state) do
    Logger.info("[DAVA] Init #{@name} server")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_academies, _from, state) do
    {:reply, FranceVae.get_academies(), state}
  end

  @impl true
  def handle_call({:get_meetings, academy_id}, _from, state) do
    {:reply, FranceVae.get_meetings(academy_id), state}
  end

  @impl true
  def handle_call({:register, meeting, application}, _from, state) do
    {:reply, FranceVae.register(meeting, application), state}
  end

  @impl true
  def handle_call({:fetch, academy_id}, _from, state) do
    {meetings, new_state} =
      Map.get_and_update(state, :"#{academy_id}", fn
        nil ->
          meetings = get_data(academy_id)

          {meetings,
           %{
             updated_at: DateTime.utc_now(),
             meetings: meetings
           }}

        %{updated_at: updated_at, meetings: meetings} = academy_meetings ->
          if DateTime.compare(
               Timex.add(updated_at, Timex.Duration.from_hours(48)),
               DateTime.utc_now()
             ) == :lt do
            {meetings,
             %{
               updated_at: DateTime.utc_now(),
               meetings: meetings
             }}
          else
            {meetings, academy_meetings}
          end

        _ ->
          # Uggly hack ...
          {[],
           %{
             updated_at: Timex.subtract(DateTime.utc_now(), Timex.Duration.from_days(3)),
             meetings: []
           }}
      end)

    {:reply, meetings, new_state}
  end

  defp get_data(academy_id) do
    FranceVae.get_meetings(academy_id)
    |> Enum.map(fn
      %Meeting{postal_code: nil} = meeting ->
        meeting

      %Meeting{postal_code: postal_code} = meeting ->
        geolocation = Vae.Places.get_geoloc_from_postal_code(postal_code)

        %{
          meeting
          | geolocation: geolocation
        }
    end)
  end
end

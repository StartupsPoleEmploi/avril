defmodule Vae.Meetings.FranceVae.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.StateHolder
  alias Vae.Meetings.FranceVae
  alias Vae.Meetings.{Delegate, Meeting}

  @name :france_vae

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, Delegate.new(@name), name: @name)
  end

  @impl true
  def init(state) do
    Logger.info("[DAVA] Init #{@name} server")

    StateHolder.subscribe(@name)

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
  def handle_call({:register_to_meeting, academy_id, meeting_id, user}, _from, state) do
    {:reply, FranceVae.register(academy_id, meeting_id, user), state}
  end

  @impl true
  def handle_call({:register, {meeting, application}}, _from, state) do
    {:reply, FranceVae.register(meeting, application), state}
  end

  @impl true
  def handle_cast({:fetch, pid, delegate}, state) do
    new_state =
      Map.merge(
        state,
        %{
          req_id: delegate.req_id,
          updated_at: DateTime.utc_now(),
          meetings: get_data()
        }
      )

    GenServer.cast(pid, {:save, @name, new_state})

    {:noreply, new_state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error(fn -> inspect("Incoming unknown msg: #{msg}") end)
    {:no_reply, state}
  end

  defp get_data() do
    FranceVae.get_academies()
    |> Enum.reduce([], fn %{"id" => academy_id}, acc ->
      [
        %{
          # Call me DB ...
          certifier_id: 2,
          academy_id: academy_id,
          meetings:
            FranceVae.get_meetings(academy_id)
            |> Enum.map(fn
              %Meeting{postal_code: nil} = meeting ->
                meeting

              %Meeting{postal_code: postal_code} = meeting ->
                geolocation = Vae.Places.get_geoloc_from_address(postal_code)

                %{
                  meeting
                  | geolocation: geolocation
                }
            end)
        }
        | acc
      ]
    end)
  end
end

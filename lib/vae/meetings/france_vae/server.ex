defmodule Vae.Meetings.FranceVae.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.StateHolder
  alias Vae.Meetings.FranceVae
  alias Vae.Meetings.Meeting

  @name FVae

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(name) do
    Logger.info("Init #{name} server")

    state = %{
      academies: [],
      meetings: []
    }

    {:ok, state, {:continue, :get_data}}
  end

  @impl true
  def handle_continue(:get_data, _state) do
    new_state = get_data()

    StateHolder.subscribe(@name, new_state)

    {:noreply, new_state}
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
  def handle_info(msg, state) do
    Logger.error(fn -> inspect("Incoming unknown msg: #{msg}") end)
    {:no_reply, state}
  end

  defp get_data() do
    FranceVae.get_academies()
    |> Enum.reduce([], fn %{"id" => id}, acc ->
      [
        %{
          # Call me DB ...
          certifier_id: 2,
          academy_id: id,
          meetings:
            FranceVae.get_meetings(id)
            |> Enum.map(fn
              %Meeting{postal_code: nil} = meeting ->
                meeting

              %Meeting{postal_code: postal_code} = meeting ->
                geolocation = Vae.Places.get_geoloc_from_address(postal_code)
                Map.put(meeting, :geolocation, geolocation)
            end)
        }
        | acc
      ]
    end)
  end
end

defmodule Vae.Meetings.FranceVae.Server do
  require Logger
  use GenServer

  alias Vae.Meetings.FranceVae
  alias Vae.Meetings.{Delegate, Meeting}

  @name :france_vae

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
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
    new_academy_meetings = %{
      updated_at: DateTime.utc_now(),
      meetings: get_data(academy_id)
    }

    new_state =
      Keyword.update(state, :"#{academy_id}", new_academy_meetings, fn
        %{meetings: meetings, updated_at: datetime} = academy_meetings ->
          case DateTime.compare(
                 Timex.add(datetime, Timex.Duration.from_hours(48)),
                 DateTime.utc_now()
               ) do
            :lt ->
              new_academy_meetings

            _ ->
              academy_meetings
          end

        _ ->
          new_academy_meetings
      end)

    {:reply, get_in(new_state, [:"#{academy_id}", :meetings]), new_state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error(fn -> "Incoming unknown msg: #{inspect(msg)}" end)
    {:noreply, state}
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

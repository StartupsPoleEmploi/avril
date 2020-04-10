defmodule Vae.Meetings.StateHolderMock do
  @meeting %{
    name: "The place 2 be",
    academy_id: 1,
    meeting_id: "12345",
    place: "Serioulsy this is the place 2 be",
    address: "502  Raccoon Run",
    postal_code: "98115",
    city: "Seattle",
    geolocation: %{},
    target: "You",
    remaining_places: 12,
    start_date: ~N[2020-04-01 10:00:00],
    end_date: ~N[2020-04-01 12:30:00]
  }

  def register("success", _application) do
    {:ok, @meeting}
  end

  def register("error", _application) do
    {:error, "{\"error\": \"une erreur est survenue\"}"}
  end

  def resgister(_meeting_id, _application) do
    raise """
    Not implemented yet !
    """
  end

  def all(), do: []
  def get(_delegate), do: %{}
  def fetch(_name), do: []
  def fetch_all(), do: %{}
  def get_by_meeting_id(_meeting_id), do: %{}
  def subscribe(_name), do: nil
end

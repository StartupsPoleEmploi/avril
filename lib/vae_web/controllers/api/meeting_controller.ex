defmodule VaeWeb.Api.MeetingController do
  use VaeWeb, :controller

  alias Vae.Repo
  alias Vae.Meetings

  def search(conn, %{"delegate_id" => delegate_id} = _params) do
    delegate =
      Repo.get(Vae.Delegate, delegate_id)
      |> Repo.preload(:certifiers)

    meetings = Meetings.get(delegate)

    json(conn, %{
      status: :ok,
      data: to_view(meetings)
    })
  end

  def to_view(meetings) do
    Enum.map(meetings, fn {{place, _address, _slug}, meetings} ->
      %{
        name: place,
        meetings:
          Enum.map(meetings, fn meeting ->
            %{
              meeting_id: meeting[:meeting_id],
              start_date: meeting[:start_date],
              end_date: meeting[:end_date],
              remaining_places: meeting[:remaining_places],
              address: meeting[:address],
              postal_code: meeting[:postal_code],
              city: meeting[:city]
            }
          end)
      }
    end)
  end
end

defmodule VaeWeb.Resolvers.Meeting do
  import VaeWeb.Resolvers.ErrorHandler

  alias Vae.{Authorities, Meetings}

  @delegate_not_found "Le certificateur est introuvable"

  def meeting_items(_, %{delegate_id: delegate_id}, _) do
    case Authorities.get_delegate(delegate_id) do
      nil ->
        error_response(
          @delegate_not_found,
          "Delegate id #{delegate_id} not found"
        )

      delegate ->
        {:ok,
         delegate
         |> Meetings.get()
         |> to_graphql()}
    end
  end

  def to_graphql(meeting_places) do
    Enum.map(meeting_places, fn {{place, _address, _slug}, meetings} ->
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

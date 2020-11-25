defmodule Vae.Authorities do
  # Depreciated
  import Ecto.Query

  alias Vae.{Delegate, Repo}

  def fetch_fvae_delegate_meetings() do
    get_france_vae_delegates()
    |> Enum.map(fn delegate ->
      with meetings <-
             Vae.Meetings.fetch_france_vae_meetings(delegate.academy_id),
           {:ok, %{task_id: task_id, index: index}} <-
             Vae.Meetings.index_france_vae_meetings(meetings),
           :ok <- Algolia.wait_task(index, task_id) do
        ordered_meetings =
          Vae.Meetings.get_france_vae_meetings(delegate)
          |> Enum.map(fn {_key, %{name: place_name, meetings: meetings}} ->
            %Vae.MeetingPlace{
              name: place_name,
              meetings: Enum.map(meetings, &struct(%Vae.Meeting{}, &1))
            }
          end)

        delegate
        |> Delegate.put_meeting_places(ordered_meetings)
        |> Repo.update()
      end
    end)
  end

  def get_france_vae_delegates() do
    from(
      d in Delegate,
      where: not is_nil(d.academy_id)
    )
    |> Repo.all()
  end
end

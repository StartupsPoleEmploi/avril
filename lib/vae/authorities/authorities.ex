defmodule Vae.Authorities do
  import Ecto.Query

  alias Vae.Delegate
  alias Vae.{SearchDelegate, Repo}

  def get_first_certifier_from_delegate(%Delegate{} = delegate) do
    Ecto.assoc(delegate, :certifiers)
    |> Repo.all()
    |> hd()
  end

  def get_first_certifier_from_delegate(_), do: nil

  def search_delegates(certification, %{lat: lat, lng: lng}, postal_code) do
    SearchDelegate.get_delegates(
      certification,
      %{"lat" => lat, "lng" => lng},
      postal_code
    )
    |> Enum.map(& &1[:id])
    |> get_delegates_from_ids()
  end

  def get_delegates_from_ids(ids) do
    from(d in Delegate,
      where: d.id in ^ids
    )
    |> Repo.all()
  end

  def get_delegate(id) do
    Repo.get(Delegate, id)
    |> Repo.preload(:certifiers)
  end

  def fetch_fvae_delegate_meetings() do
    get_france_vae_delegate()
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

  def get_france_vae_delegate() do
    from(
      d in Delegate,
      where: not is_nil(d.academy_id)
    )
    |> Repo.all()
  end
end

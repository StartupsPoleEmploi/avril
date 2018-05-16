defmodule Mix.Tasks.Delegate.Geocode do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Delegate
  alias Vae.AlgoliaPlaces

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with true <- geocode_delegates() do
      {:ok, "Well done !"}
    end
  end

  def geocode_delegates() do
    Delegate.all()
    |> Enum.map(&geocode_delegate/1)
    |> Enum.map(&Repo.update/1)
  end

  def geocode_delegate(delegate) do
    geolocation = AlgoliaPlaces.get_first_hit_to_index(delegate.address)

    geolocation_params = %{
      geolocation: geolocation,
      city: AlgoliaPlaces.get_city(geolocation),
      administrative: AlgoliaPlaces.get_administrative(geolocation)
    }

    delegate |> Delegate.changeset(geolocation_params)
  end
end

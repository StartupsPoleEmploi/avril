defmodule Mix.Tasks.Delegate.FillPostgisData do
  alias Vae.{Delegate, Repo, Places.Ban}
  import Ecto.Query

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    fill_geometry()
  end

  def fill_geometry() do
    from(d in Delegate, where: not is_nil(d.geolocation) and not is_nil(d.address))
    |> Repo.all()
    |> Enum.map(fn %Delegate{address: address} = d ->
        coordinates = address
        |> Ban.get_geoloc_from_address()
        |> Ban.get_field(:lat_lng)
      Delegate.changeset(d, %{geom: %Geo.Point{coordinates: coordinates}})
      |> Repo.update()
    end)
  end
end
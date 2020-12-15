defmodule Mix.Tasks.Delegate.FillPostgisData do
  alias Vae.{Delegate, Repo}
  import Ecto.Query

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    fill_geometry()
  end

  def fill_geometry() do
    from(d in Delegate, where: not is_nil(d.geolocation) and is_nil(d.geom))
    |> Repo.all()
    |> Enum.map(fn d ->
      Delegate.changeset(d, %{
        geom: %Geo.Point{coordinates: get_lat_lng(d)},
        geolocation: d.geolocation["geolocation"] || d.geolocation
      })
      |> Repo.update()
    end)
  end

  defp get_lat_lng(%Delegate{geolocation: %{"_geoloc" => %{"lng" => lng, "lat" => lat}}}) do
    {lng, lat}
  end

  defp get_lat_lng(%Delegate{geolocation: %{"geolocation" => %{"_geoloc" => %{"lng" => lng, "lat" => lat}}}}) do
    {lng, lat}
  end

end
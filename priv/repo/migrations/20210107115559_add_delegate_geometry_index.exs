defmodule Vae.Repo.Migrations.AddDelegateGeometryIndex do
  use Ecto.Migration

  def change do

    execute("CREATE INDEX delegates_geom_idx ON delegates USING GIST (geom);")
  end
end

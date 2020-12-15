defmodule Vae.Repo.Migrations.AddGeometryToDelegate do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add :geom,     :geometry
      remove :contact
      remove :step_4

    end
  end
end

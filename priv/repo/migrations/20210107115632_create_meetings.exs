defmodule Vae.Repo.Migrations.CreateMeetings do
  use Ecto.Migration

  def change do
    create table(:meetings) do
      add :source, :string, null: false
      add :data, :map, null: false
      add :geom, :geometry, null: false

      timestamps()
    end

    execute("CREATE INDEX meetings_geom_idx ON meetings USING GIST (geom);")

    alter table(:applications) do
      remove :meeting, :map
      add :meeting_id, references(:meetings, on_delete: :nilify_all)
    end

    alter table(:delegates) do
      remove(:meeting_places, {:array, :jsonb}, default: [])
    end

  end
end

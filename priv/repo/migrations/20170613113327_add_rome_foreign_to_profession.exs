defmodule Vae.Repo.Migrations.AddRomeForeignToProfession do
  use Ecto.Migration

  def change do
    alter table(:professions) do
      add :rome_id, references(:romes)
    end
  end
end

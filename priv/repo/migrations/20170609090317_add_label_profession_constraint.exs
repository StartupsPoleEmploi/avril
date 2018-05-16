defmodule Vae.Repo.Migrations.AddLabelProfessionConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:professions, [:label])
  end
end

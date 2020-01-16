defmodule Vae.Repo.Migrations.AddDbConstraintsPostSanitization do
  use Ecto.Migration

  def change do
    create unique_index(:certifications, [:slug])
    create unique_index(:certifiers, [:slug])
    create unique_index(:romes, [:slug])
    # create unique_index(:delegates, [:slug])
    # create unique_index(:professions, [:slug])
  end
end

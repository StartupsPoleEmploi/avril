defmodule Vae.Repo.Migrations.CreateDelegatesTable do
  use Ecto.Migration

  def change do
    create table(:delegates) do
      add :name, :string, null: false
      add :website, :string
      add :address, :map
      add :contact, :map

      add :certifier_id, references(:certifiers)

      timestamps()
    end
    create unique_index(:delegates, [:name])
  end
end

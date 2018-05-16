defmodule Vae.Repo.Migrations.CreateCertifiers do
  use Ecto.Migration

  def change do
    create table(:certifiers) do
      add :name, :string, null: false

      timestamps()
    end
  end
end

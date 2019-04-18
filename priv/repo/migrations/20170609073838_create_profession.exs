defmodule Vae.Repo.Migrations.CreateProfession do
  use Ecto.Migration

  def change do
    create table(:professions) do
      add(:label, :string)

      timestamps()
    end
  end
end

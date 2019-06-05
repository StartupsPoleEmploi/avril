defmodule Vae.Repo.Migrations.AddIsFeaturedToProfession do
  use Ecto.Migration

  def change do
    alter table(:professions) do
      add(:priority, :integer, default: 0)
    end
  end
end

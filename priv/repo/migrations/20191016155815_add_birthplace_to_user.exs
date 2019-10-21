defmodule Vae.Repo.Migrations.AddBirthplaceToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:birth_place, :string)
    end
  end
end

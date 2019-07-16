defmodule Vae.Repo.Migrations.AddGenderToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:gender, :string)
    end
  end
end

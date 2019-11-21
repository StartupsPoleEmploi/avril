defmodule Vae.Repo.Migrations.AddBooklet1ToApplication do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add(:booklet_1, :map)
    end
  end
end

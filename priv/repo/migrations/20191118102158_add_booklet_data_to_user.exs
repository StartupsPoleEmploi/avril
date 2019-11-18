defmodule Vae.Repo.Migrations.AddBookletDataToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:booklet_data, :map)
    end
  end
end

defmodule Vae.Repo.Migrations.AddBookletHashToApplication do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add(:booklet_hash, :string)
    end

    create unique_index(:applications, :booklet_hash, name: :application_booklet_hash_unicity_index)
  end
end

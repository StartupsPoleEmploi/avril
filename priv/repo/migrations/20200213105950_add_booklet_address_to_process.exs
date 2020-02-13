defmodule Vae.Repo.Migrations.AddBookletAddressToProcess do
  use Ecto.Migration

  def change do
    alter table(:processes) do
      add(:booklet_address, :string)
    end
  end
end

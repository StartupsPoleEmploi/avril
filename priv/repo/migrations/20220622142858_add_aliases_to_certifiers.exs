defmodule Vae.Repo.Migrations.AddAliasesToCertifiers do
  use Ecto.Migration

  def change do
    alter table(:certifiers) do
      add(:aliases, :text)
    end
  end
end

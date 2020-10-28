defmodule Vae.Repo.Migrations.AddSiretToCertifier do
  use Ecto.Migration

  def change do
    alter table(:certifiers) do
      add(:siret, :string)
    end
    create unique_index(:certifiers, [:siret], name: :certifiers_siret_unicity_index)
  end
end

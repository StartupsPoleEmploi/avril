defmodule Vae.Repo.Migrations.AddLabelUniquenessOnCertifiers do
  use Ecto.Migration

  def change do
    create(unique_index(:certifiers, [:name]))
  end
end

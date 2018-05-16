defmodule Vae.Repo.Migrations.AddRomeConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:romes, [:code])
  end
end

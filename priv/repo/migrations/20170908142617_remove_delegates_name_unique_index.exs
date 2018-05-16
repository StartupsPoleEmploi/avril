defmodule Vae.Repo.Migrations.RemoveDelegatesLabelConstraint do
  use Ecto.Migration

  def change do
    drop index(:delegates, [:name])
  end
end

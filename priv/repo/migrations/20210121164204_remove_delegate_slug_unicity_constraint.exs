defmodule Vae.Repo.Migrations.RemoveDelegateSlugUnicityConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:certifications, [:slug])
    drop unique_index(:certifiers, [:slug])
  end
end

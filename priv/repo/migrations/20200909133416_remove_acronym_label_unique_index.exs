defmodule Vae.Repo.Migrations.RemoveAcronymLabelUniqueIndex do
  use Ecto.Migration

  def change do
    drop index(:certifications, [:acronym, :label])
  end
end

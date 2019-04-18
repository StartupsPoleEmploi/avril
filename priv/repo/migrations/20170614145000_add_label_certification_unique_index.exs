defmodule Vae.Repo.Migrations.AddLabelCertificationUniqueIndex do
  use Ecto.Migration

  def change do
    create(unique_index(:certifications, [:label]))
  end
end

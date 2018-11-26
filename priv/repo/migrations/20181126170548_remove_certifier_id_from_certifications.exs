defmodule Vae.Repo.Migrations.RemoveCertifierIdFromCertifications do
  use Ecto.Migration

  def change do
    drop_if_exists(index(:certifications, [:certifier_id]))

    alter table(:certifications) do
      remove(:certifier_id)
    end
  end
end

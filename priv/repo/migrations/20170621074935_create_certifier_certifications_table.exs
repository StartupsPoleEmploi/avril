defmodule Vae.Repo.Migrations.CreateCertifierCertificationsTable do
  use Ecto.Migration

  def change do
    create table(:certifier_certifications, primary_key: false) do
      add :certifier_id, references(:certifiers)
      add :certification_id, references(:certifications)
    end
  end
end

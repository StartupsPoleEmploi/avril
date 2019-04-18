defmodule Vae.Repo.Migrations.CreateRomeCertificationsTable do
  use Ecto.Migration

  def change do
    create table(:rome_certifications, primary_key: false) do
      add(:rome_id, references(:romes))
      add(:certification_id, references(:certifications))
    end
  end
end

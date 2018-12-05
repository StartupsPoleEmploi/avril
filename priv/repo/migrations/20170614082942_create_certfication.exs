defmodule Vae.Repo.Migrations.CreateCertfication do
  use Ecto.Migration

  def change do
    create table(:certifications) do
      add(:label, :string)
      add(:description, :string)
      timestamps()
    end
  end
end

defmodule Vae.Repo.Migrations.AddIsRncpActiveToCertification do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add :is_rncp_active, :boolean, default: true
      add :last_rncp_import_date, :date
      add :end_of_rncp_validity, :date
    end
  end
end

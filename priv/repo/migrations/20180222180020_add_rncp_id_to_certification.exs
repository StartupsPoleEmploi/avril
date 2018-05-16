defmodule Vae.Repo.Migrations.AddRncpIdToCertification do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      add :rncp_id, :string
    end
  end
end

defmodule Vae.Repo.Migrations.MakeRncpIdMandatory do
  use Ecto.Migration

  def change do
    alter table(:certifications) do
      modify :rncp_id, :string, null: false
    end

    create unique_index(:certifications, [:rncp_id], name: :certifications_rncp_id_unicity_index)

  end
end

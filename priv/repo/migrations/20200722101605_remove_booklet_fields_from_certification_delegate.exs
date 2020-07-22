defmodule Vae.Repo.Migrations.RemoveBookletFieldsFromCertificationDelegate do
  use Ecto.Migration

  def change do
    alter table(:certifications_delegates) do
      remove :booklet_1
      remove :booklet_2
    end
  end
end

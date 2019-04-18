defmodule Vae.Repo.Migrations.AddCertificationDelegatesTable do
  use Ecto.Migration

  def change do
    create table(:processes) do
      add(:name, :string)
      add(:booklet_1, :string)
      add(:booklet_2, :string)
    end

    create(unique_index(:processes, [:name]))

    create table(:certifications_delegates) do
      add(:booklet_1, :string)
      add(:booklet_2, :string)
      add(:certification_id, references(:certifications))
      add(:delegate_id, references(:delegates))
    end

    alter table(:delegates) do
      add(:process_id, references(:processes))
    end
  end
end

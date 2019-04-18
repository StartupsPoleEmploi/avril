defmodule Vae.Repo.Migrations.RemoveAssociationsFromUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove(:delegate_id)
      remove(:certification_id)
      add(:proven_experiences, {:array, :jsonb}, default: [])
    end
  end

  def down do
    alter table(:users) do
      add(:delegate_id, references(:delegates))
      add(:certification_id, references(:certifications))
      remove(:proven_experiences)
    end
  end
end

defmodule Vae.Repo.Migrations.AddCertifiersDelegatesManyToManyAssoc do
  use Ecto.Migration

  def change do
    create table(:certifiers_delegates) do
      add(:delegate_id, references(:delegates))
      add(:certifier_id, references(:certifiers))
    end

    alter table(:delegates) do
      remove(:certifier_id)
    end
  end
end

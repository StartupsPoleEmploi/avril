defmodule Vae.Repo.Migrations.RemoveCertifierIdFromDelegates do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      remove(:certifier_id)
    end
  end
end

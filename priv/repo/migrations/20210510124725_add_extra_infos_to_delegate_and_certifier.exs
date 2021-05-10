defmodule Vae.Repo.Migrations.AddExtraInfosToDelegateAndCertifier do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add :external_notes, :text
    end
    alter table(:certifiers) do
      add :external_notes, :text
    end
  end
end

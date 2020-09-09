defmodule Vae.Repo.Migrations.AddInternalNotesOnDelegates do
  use Ecto.Migration

  def change do
    alter table(:delegates) do
      add :internal_notes, :text
      add :secondary_email, :string
      add :secondary_person_name, :string
    end
  end
end

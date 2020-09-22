defmodule Vae.Repo.Migrations.MakeDelegatePersonNameFacultative do
  use Ecto.Migration

  def up do
    alter table(:delegates) do
      modify :person_name, :string, null: true
    end
  end

  def down do
    alter table(:delegates) do
      modify :person_name, :string, null: false
    end
  end
end

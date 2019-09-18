defmodule Vae.Repo.Migrations.MakeDelegatePersonNameMandatory do
  use Ecto.Migration

  def up do
    # Run
    # import Ecto.Query
    # Vae.Repo.update_all(
    #  from(d in Vae.Delegate,
    #  where: is_nil(d.person_name)),
    #  set: [person_name: "Mon conseiller VAE"]
    # )
    alter table(:delegates) do
      modify :person_name, :string, null: false
    end
  end

  def down do
    alter table(:delegates) do
      modify :person_name, :string, null: true
    end
  end
end

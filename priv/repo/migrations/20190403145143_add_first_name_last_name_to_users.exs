defmodule Vae.Repo.Migrations.AddFirstNameLastNameToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add(:first_name, :string)
      add(:last_name, :string)
    end

    flush()

    Enum.map(Vae.Repo.all(Vae.User), fn user ->
      [first_name, last_name] = String.split(user.name, " ", parts: 2)

      Vae.User.changeset(user, %{
        first_name: first_name,
        last_name: last_name
      })
      |> Vae.Repo.update()
    end)
  end

  def down do
    Enum.map(Vae.Repo.all(Vae.User), fn user ->
      Vae.User.changeset(user, %{
        name: "#{user.first_name} #{user.last_name}"
      })
      |> Vae.Repo.update()
    end)

    alter table(:users) do
      remove(:first_name)
      remove(:last_name)
    end
  end
end

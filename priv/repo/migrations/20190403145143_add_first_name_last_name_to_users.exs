defmodule Vae.Repo.Migrations.AddFirstNameLastNameToUsers do
  use Ecto.Migration

  def change do
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
      }) |> Vae.Repo.update
    end)

    alter table(:users) do
      remove(:name)
    end

  end
end

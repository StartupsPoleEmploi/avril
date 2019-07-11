defmodule Vae.Repo.Migrations.ChangeArrayJsonbToJsonbInUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:skills_2, :jsonb, default: "[]")
      add(:experiences_2, :jsonb, default: "[]")
      add(:proven_experiences_2, :jsonb, default: "[]")
    end

    flush()

    migrate(:skills, :skills_2)
    migrate(:experiences, :experiences_2)
    migrate(:proven_experiences, :proven_experiences_2)
  end

  defp migrate(old, new) do
    users = Vae.Repo.all(Vae.User)

    Enum.map(users, fn user ->
      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_embed(new, Map.get(user, old))
      |> Vae.Repo.update!()
    end)
  end
end

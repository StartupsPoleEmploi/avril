defmodule Vae.Repo.Migrations.ChangeCertificationCertifierRelationOneToMany do
  use Ecto.Migration

  alias Vae.{Repo, Certification, Certifier}
  alias Ecto.Changeset

  def change do
    alter table(:certifications) do
      add(:certifier_id, references(:certifiers, on_delete: :nilify_all))
    end

    create(index(:certifications, [:certifier_id]))

    flush()

    migrate_certifications()
  end

  defp migrate_certifications() do
    Repo.all(Certification)
    |> Repo.preload(:certifiers)
    |> Enum.map(fn certification ->
      certification.certifiers
      |> migrate(certification)
    end)
  end

  defguardp no_certifiers(certifiers) when length(certifiers) == 0
  defguardp has_one_certifier(certifiers) when length(certifiers) == 1

  defp migrate(certifiers, certification) when no_certifiers(certifiers) do
    social_ministry = Repo.get(Certifier, 4)
    update!(social_ministry, certification)
  end

  defp migrate(certifier, certification) when has_one_certifier(certifier),
    do: update!(hd(certifier), certification)

  defp migrate(certifiers, certification) do
    certifiers
    |> Enum.uniq()
    |> case do
      certifier when has_one_certifier(certifier) ->
        migrate(certifier, certification)

      certifiers ->
        certifiers
        |> Enum.find(Enum.at(certifiers, 0), &(&1.id == 2))
        |> update!(certification)
    end
  end

  defp update!(certifier, certification) do
    certification
    |> Repo.preload(:certifier)
    |> Changeset.change()
    |> Changeset.put_assoc(:certifier, certifier)
    |> Repo.update()
  end
end

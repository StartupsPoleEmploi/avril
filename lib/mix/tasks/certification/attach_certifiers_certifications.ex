defmodule Mix.Tasks.Certification.AttachCertifiersCertifications do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Certification

  def run(_args) do
    {:ok, _pid, _apps} = ensure_started(Vae.Repo, [])

    certifications = Repo.all(Certification) |> Repo.preload(:certifiers)

    certifications
    |> Enum.map(fn certification ->
      certifier = Ecto.assoc(certification, :certifier) |> Repo.one()

      certification
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:certifiers, [certifier])
      |> Repo.update!()
    end)
  end
end

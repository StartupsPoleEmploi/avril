defmodule Mix.Tasks.Certification.AttachCertifiersCertifications do
  use Mix.Task

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.Certification

  def run(_args) do
    # {:ok, _pid, _apps} = ensure_started(Vae.Repo, [])

    Repo.all(Certification)
    |> Repo.preload(:certifiers)
    |> Enum.map(fn certification ->
      certifier = Ecto.assoc(certification, :certifier) |> Repo.one()

      if is_nil(certifier) do
        true
      else
        certification
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:certifiers, [certifier])
        |> Repo.update!()
      end
    end)
  end
end

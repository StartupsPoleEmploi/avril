defmodule Mix.Tasks.Delegate.AttachCertifiersToDelegate do
  use Mix.Task

  require Logger

  alias Vae.Repo
  alias Vae.{Certifier, Delegate}

  def run(_args) do
    # ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    extract()
    |> attach_certifiers()
  end

  def extract() do
    Repo.all(Delegate)
    |> Repo.preload(:certifiers)
  end

  def attach_certifiers(delegates) do
    delegates
    |> Enum.reduce([], fn delegate, acc ->
      case delegate.certifier_id do
        nil ->
          acc

        certifier_id ->
          certifier = Repo.get!(Certifier, certifier_id)

          [
            delegate
            |> Ecto.Changeset.change()
            |> Ecto.Changeset.put_assoc(:certifiers, [certifier])
            | acc
          ]
      end
    end)
    |> Enum.map(&Repo.update!/1)
  end
end

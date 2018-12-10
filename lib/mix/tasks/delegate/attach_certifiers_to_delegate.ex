defmodule Mix.Tasks.Delegate.AttachCertifiersToDelegate do
  use Mix.Task

  require Logger

  import Mix.Ecto

  alias Vae.Repo
  alias Vae.{Certifier, Delegate}

  def run(_args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with delegates <- extract(),
         updated_delegates <- attach_certifiers(delegates),
         {:ok, _objects} <- index(updated_delegates),
         {:ok, _details} <- move_index() do
      Logger.info("Hey dude... all done !")
    else
      msg -> Logger.error(fn -> inspect(msg) end)
    end
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

  def index(delegates) do
    with {:ok, _index_details} <-
           Algolia.set_settings("delegate_tmp", %{
             "attributeForDistinct" => "name",
             "distinct" => 1
           }) do
      Algolia.save_objects(
        "delegate_tmp",
        delegates
        |> Enum.map(&Repo.NewRelic.format_delegate_for_index/1),
        id_attribute: :id
      )
    end
  end

  def move_index(), do: Algolia.move_index("delegate_tmp", "delegate")
end

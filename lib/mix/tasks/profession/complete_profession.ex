defmodule Mix.Tasks.Profession.CompleteProfession do
  require Logger
  use Mix.Task

  alias Ecto.Multi

  alias Vae.Search.Algolia
  alias Vae.Repo
  alias Vae.{Profession, Rome}

  def run(_args) do
    with {:ok, _} = Application.ensure_all_started(:vae),
         romes <- Repo.all(Rome) do
      load_csv("priv/fixtures/complete_professions.csv")
      |> Enum.map(fn %{"CODE" => rome_code, "LABEL" => label} ->
        rome = Enum.find(romes, fn rome -> rome.code == rome_code end)

        %{
          label: label,
          rome_id: rome.id,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now(),
          slug: Vae.String.parameterize(label)
        }
      end)
      |> delete_and_insert()
      |> case do
        {:ok, professions} ->
          Algolia.index(professions)

        {:error, error} ->
          Logger.error(fn -> inspect(error) end)
      end
    end
  end

  def load_csv(path) do
    File.stream!(path)
    |> CSV.decode!(separator: ?,, headers: true)
  end

  def delete_and_insert(profession_maps) do
    Multi.new()
    |> Multi.delete_all(:delete_all, Profession)
    |> Multi.insert_all(:insert_all, Profession, profession_maps, returning: true)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_all: _delete_al, insert_all: {_number, professions}}} ->
        professions = Repo.preload(professions, :rome)
        {:ok, professions}

      {:error, error} = error ->
        error

      error ->
        {:error, error}
    end
  end
end

defmodule Mix.Tasks.Search.Index do
  use Mix.Task

  require Logger
  import Mix.Ecto
  import Ecto.Query, only: [from: 2]

  import Vae.Search.Client.Algolia, only: [get_index_name: 1]

  alias Vae.Repo
  alias Vae.Delegate
  alias Vae.Profession

  @moduledoc """
  Index DB entries for the given model.

  ## Examples
    mix search.index -m Vae.Delegate
    mix search.index -m Vae.Rome -m Vae.Profession -m Vae.Certification -c

  ## Command line options

  * `-m`, `--model` - the models to index
  * `-c`, `--clear-before` - clear index before indexing
  """

  def run(args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with {parsed, _argv, []} <- option_parser(args),
         {:ok, models} <- get_models(parsed) do
      if Keyword.get(parsed, :clear_before, false) do
        Enum.map(models, &clear_index/1)
      end

      Enum.map(models, &get_and_index/1)
    else
      {_parsed, _args, errors} -> Logger.error(fn -> inspect(errors) end)
      {:error, msg} -> Logger.error(fn -> inspect(msg) end)
    end
  end

  defp option_parser(args) do
    OptionParser.parse(args,
      aliases: [m: :model, c: :clear_before],
      strict: [model: :keep, clear_before: :boolean]
    )
  end

  defp get_models(parsed) do
    models = Keyword.get_values(parsed, :model)

    if models != [] do
      {:ok, Enum.map(models, &Module.concat([&1]))}
    else
      {:error, "You must provide a model name"}
    end
  end

  defp clear_index(model) do
    model
    |> get_index_name()
    |> Algolia.clear_index()
  end

  defp get_and_index(model) do
    with entries <- get(model),
         {:ok, _index_details} <- index_settings(model),
         {:ok, index_info} <- index(entries, model) do
      Logger.info(
        "#{length(index_info["objectIDs"])} #{index_info["indexName"]} have been indexed"
      )
    else
      {:error, msg} -> Logger.error(fn -> inspect(msg) end)
      msg -> Logger.error(fn -> inspect(msg) end)
    end
  end

  # TODO: Remove this when no more limitations from algolia
  defp get(Profession) do
    query =
      from(p in Profession,
        join: r in "rome_certifications",
        on: p.rome_id == r.rome_id,
        group_by: p.id,
        select: p
      )

    Repo.all(query)
    |> Repo.preload(:rome)
  end

  defp get(model) do
    Repo.all(model)
  end

  defp index_settings(Delegate) do
    settings = %{
      "attributesForFaceting" => ["is_active"],
      "attributeForDistinct" => "name",
      "distinct" => 1
    }

    Algolia.set_settings("delegate", settings)
  end

  defp index_settings(_model) do
    {:ok, nil}
  end

  defp index(entries, model) do
    objects = Enum.map(entries, &model.format_for_index/1)
    Algolia.save_objects(get_index_name(model), objects, id_attribute: :id)
  end
end

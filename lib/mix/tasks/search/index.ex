defmodule Mix.Tasks.Search.Index do
  use Mix.Task

  require Logger

  alias Vae.Search.Algolia

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
    {:ok, _} = Application.ensure_all_started(:vae)

    with {parsed, _argv, []} <- option_parser(args),
         {:ok, models} <- cli_option_to_modules(parsed) do
      if Keyword.get(parsed, :clear_before, false) do
        Enum.each(models, &Algolia.clear_index(&1))
      end

      Enum.map(models, &set_settings_and_index(&1))
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

  defp cli_option_to_modules(parsed) do
    models = Keyword.get_values(parsed, :model)

    if models != [] do
      {:ok, Enum.map(models, &Module.concat([&1]))}
    else
      {:error, "You must provide a model name"}
    end
  end

  defp set_settings_and_index(model) do
    with(
      {:ok, _settings_infos} <- Algolia.set_settings(model),
      {:ok, index_info} <- Algolia.index(model)
    ) do
      Logger.info(
        "#{length(index_info["objectIDs"])} #{model} have been indexed in #{index_info["indexName"]}"
      )
    else
      {:error, msg} -> Logger.error(fn -> inspect(msg) end)
      msg -> Logger.error(fn -> inspect(msg) end)
    end
  end

end

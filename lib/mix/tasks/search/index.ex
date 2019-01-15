defmodule Mix.Tasks.Search.Index do
  use Mix.Task

  require Logger
  import Mix.Ecto

  alias Vae.Delegate

  @moduledoc """
  Index DB entries for the given model.

  ## Examples
    mix search.index -m Vae.Delegate

  ## Command line options

  * `-m`, `--model` - the model to index
  """

  def run(args) do
    ensure_started(Repo, [])
    {:ok, _started} = Application.ensure_all_started(:httpoison)

    with {:ok, model} <- parse_args(args),
         entries <- Repo.all(model),
         {:ok, _index_details} <- index(entries, model),
         {:ok, _op} <- move_index(model) do
      Logger.info("#{length(entries)} #{model} have been indexed")
    else
      {:error, msg} -> Logger.error(fn -> inspect(msg) end)
      msg -> Logger.error(fn -> inspect(msg) end)
    end
  end

  defp parse_args([]), do: {:error, "You must provide a model name"}

  defp parse_args([key, value | _t]) when key in ~w(--model -m) and not is_nil(value) do
    {:ok, Module.concat([value])}
  end

  defp parse_args(args), do: {:error, "Unknown args: #{inspect(args)}"}

  defp index(delegates, model) do
    with {:ok, _index_details} <-
           Algolia.set_settings("delegate_tmp", %{
             "attributeForDistinct" => "name",
             "distinct" => 1
           }) do
      model
      |> (fn model -> "#{get_index_name(model)}_tmp" end).()
      |> Algolia.save_objects(
        delegates
        |> Enum.map(&Delegate.format_for_index/1),
        id_attribute: :id
      )
    end
  end

  defp move_index(model) do
    index_name = get_index_name(model)
    Algolia.move_index("#{index_name}_tmp", "#{index_name}")
  end

  defp get_index_name(model) do
    model
    |> to_string()
    |> String.split(".")
    |> List.last()
    |> String.downcase()
  end
end

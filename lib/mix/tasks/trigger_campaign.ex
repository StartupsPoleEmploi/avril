defmodule Mix.Tasks.TriggerCampaign do
  use Mix.Task

  @possible_types [:reinscrits, :primo_inscrits]

  def run([type_str, date_str]) do
    {:ok, _} = Application.ensure_all_started(:vae)

    # [:postgrex, :ecto]
    # |> Enum.each(&Application.ensure_all_started/1)

    type = String.to_atom(type_str)

    if Enum.member?(@possible_types, type) do
      case Date.from_iso8601(date_str) do
        {:ok, date} ->
          Vae.CampaignDiffuser.Handler.execute(type, date)
        {:error, error} -> error
      end
    else
      IO.puts("Possible type values: #{Enum.join(@possible_types, " - ")}")
    end
  end
end
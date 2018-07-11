defmodule Vae.Crm do
  require Logger

  @fields ~w(IDENTIFIANT PRENOM NOM COURRIEL TELEPHONE CODE_POSTAL LSNIVEAUENMAX)

  def extract() do
    "priv/fixtures/extract.csv"
    |> File.stream!(read_ahead: 100_000)
    |> CSV.decode(separator: ?;, headers: true)
    |> Enum.map(fn
      {:ok, line} -> Map.take(line, @fields)
      {:error, error} -> Logger.error(error)
    end)
    |> Enum.to_list()
  end
end

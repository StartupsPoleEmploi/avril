defmodule Vae.Crm do
  require Logger

  @fields ~w(IDENTIFIANT PRENOM NOM COURRIEL TELEPHONE CODE_POSTAL LSNIVEAUENMAX)

  def extract() do
    "priv/fixtures/test.csv"
    |> File.stream!(read_ahead: 100_000)
    |> CSV.decode(separator: ?;, headers: true)
    |> Enum.map(fn
      {:ok, line} -> Map.take(line, @fields)
      {:error, error} -> Logger.error(error)
    end)
    |> Enum.map(&build_job_seeker/1)
    |> Enum.to_list()
  end

  def build_job_seeker(line) do
    %Vae.JobSeeker{
      identifier: line["IDENTIFIANT"],
      first_name: String.capitalize(line["PRENOM"]),
      last_name: String.capitalize(line["NOM"]),
      email: line["COURRIEL"],
      telephone: line["TELEPHONE"],
      postal_code: line["CODE_POSTAL"]
    }
  end

  def send() do
    extract()
    |> Enum.map(fn job_seeker -> Vae.Email.send_campain_email(job_seeker) end)
  end
end

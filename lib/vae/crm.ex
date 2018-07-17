defmodule Vae.Crm do
  require Logger

  def extract_test() do
    "priv/fixtures/VAE_FULL_2018-07-08.csv"
    |> File.stream!(read_ahead: 100_000)
    |> Stream.take(4)
    |> extract()
  end

  @fields ~w(KN_INDIVIDU_NATIONAL PRENOM NOM COURRIEL TELEPHONE CODE_POSTAL NIV_EN_FORMATION1_NUM ROME1V3 NROM1EXP ROME2V3 NROM2EXP)

  def extract(stream) do
    stream
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
      identifier: line["KN_INDIVIDU_NATIONAL"],
      first_name: String.capitalize(line["PRENOM"]),
      last_name: String.capitalize(line["NOM"]),
      email: line["COURRIEL"],
      telephone: line["TELEPHONE"],
      postal_code: line["CODE_POSTAL"],
      education_level: line["NIV_EN_FORMATION1_NUM"],
      experience:
        %{
          line["ROME1V3"] =>
            line["NROM1EXP"] |> Float.parse()
            |> case do
              :error -> 0
              {level, _} -> level
            end,
          line["ROME2V3"] =>
            line["NROM2EXP"] |> Float.parse()
            |> case do
              :error -> 0
              {level, _} -> level
            end
        }
        |> Map.delete("")
    }
  end

  def send(job_seekers) do
    job_seekers
    |> Enum.map(fn job_seeker -> Vae.Email.send_campain_email(job_seeker) end)
  end
end

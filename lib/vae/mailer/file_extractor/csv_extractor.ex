defmodule Vae.Mailer.FileExtractor.CsvExtractor do
  require Logger

  @behaviour Vae.Mailer.FileExtractor

  alias Vae.JobSeeker
  alias Vae.Repo.NewRelic, as: Repo

  @fields ~w(KN_INDIVIDU_NATIONAL PRENOM NOM COURRIEL TELEPHONE CODE_POSTAL NIV_EN_FORMATION1_NUM ROME1V3 NROM1EXP ROME2V3 NROM2EXP)

  def extract(path, _) do
    window = Flow.Window.count(10_000)

    File.stream!(path, read_ahead: 100_000)
    |> CSV.decode(separator: ?;, headers: true)
    |> Flow.from_enumerable()
    |> Flow.map(fn
      {:ok, line} -> Map.take(line, @fields)
      {:error, error} -> Logger.error(error)
    end)
    |> Flow.map(&build_job_seeker/1)
    |> Flow.partition(window: window)
    |> Flow.reduce(fn -> [] end, fn job_seeker, acc ->
      case Repo.get_by(JobSeeker, email: job_seeker.email) do
        nil -> [job_seeker | acc]
        _ -> acc
      end
    end)
    |> Flow.on_trigger(fn acc ->
      new_acc = Enum.map(acc, &build_geolocation/1)

      {new_acc, []}
    end)
    |> Enum.to_list()
  end

  defp build_geolocation(job_seeker) do
    geolocation = Vae.Places.get_geoloc_from_postal_code(job_seeker.postal_code)
    Map.put(job_seeker, :geolocation, geolocation)
  end

  defp build_job_seeker(line) do
    %JobSeeker{
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
            line["NROM1EXP"]
            |> Float.parse()
            |> case do
              :error -> 0
              {level, _} -> level
            end,
          line["ROME2V3"] =>
            line["NROM2EXP"]
            |> Float.parse()
            |> case do
              :error -> 0
              {level, _} -> level
            end
        }
        |> Map.delete("")
    }
  end
end

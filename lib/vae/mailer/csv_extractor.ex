defmodule Vae.Mailer.CsvExtractor do
  require Logger

  alias Vae.JobSeeker
  alias Vae.Mailer.Email

  @stages 5

  @fields ~w(KN_INDIVIDU_NATIONAL PRENOM NOM COURRIEL TELEPHONE CODE_POSTAL NIV_EN_FORMATION1_NUM ROME1V3 NROM1EXP ROME2V3 NROM2EXP)

  def extract(path, existing_custom_ids) do
    File.stream!(path, read_ahead: 100_000)
    |> CSV.decode(separator: ?;, headers: true)
    |> Flow.from_enumerable()
    |> Flow.partition(stages: @stages)
    |> Flow.map(fn
      {:ok, line} -> Map.take(line, @fields)
      {:error, error} -> Logger.error(error)
    end)
    |> Flow.partition(stages: @stages)
    |> Flow.map(&build_job_seeker/1)
    |> Flow.partition(stages: @stages)
    |> Flow.reduce(fn -> [] end, fn job_seeker, acc ->
      custom_id = UUID.uuid5(nil, job_seeker.email)

      if Enum.member?(existing_custom_ids, custom_id) do
        acc
      else
        [
          %Email{
            custom_id: custom_id,
            job_seeker: job_seeker
          }
          | acc
        ]
      end
    end)
    |> Enum.to_list()
  end

  defp build_job_seeker(line) do
    %JobSeeker{
      identifier: line["KN_INDIVIDU_NATIONAL"],
      first_name: String.capitalize(line["PRENOM"]),
      last_name: String.capitalize(line["NOM"]),
      email: line["COURRIEL"],
      telephone: line["TELEPHONE"],
      postal_code: line["CODE_POSTAL"],
      geolocation: Vae.AlgoliaPlaces.get_first_hit_to_index(line["CODE_POSTAL"]),
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

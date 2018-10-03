defmodule Vae.Mailer.FileExtractor.CsvExtractor do
  require Logger

  alias Vae.Places

  @behaviour Vae.Mailer.FileExtractor

  @limit Application.get_env(:vae, :mailer_extractor_limit)

  @fields ~w(KN_INDIVIDU_NATIONAL PRENOM NOM COURRIEL TELEPHONE CODE_POSTAL NIV_EN_FORMATION1_NUM ROME1V3 NROM1EXP ROME2V3 NROM2EXP)

  @allowed_administratives [
    "Bretagne",
    "Île-de-France",
    "Centre-Val de Loire",
    "Occitanie",
    "Bourgogne-Franche-Comté",
    "Provence-Alpes-Côte d'Azur",
    "Corse",
    "Hauts-de-France",
    "Auvergne-Rhône-Alpes",
    "Nouvelle-Aquitaine"
  ]

  def extract(path) do
    job_seekers_flow =
      File.stream!(path, read_ahead: 100_000)
      |> CSV.decode(separator: ?;, headers: true)
      |> Flow.from_enumerable()
      |> Flow.map(fn
        {:ok, line} -> Map.take(line, @fields)
        {:error, error} -> Logger.error(error)
      end)
      |> Flow.map(&build_job_seeker/1)
      |> Flow.reduce(fn -> [] end, fn job_seeker, acc ->
        located_job_seeker = build_geolocation(job_seeker)
        [located_job_seeker | acc]
      end)
      |> Flow.filter(&is_allowed_administrative?/1)

    case @limit do
      :all -> Enum.to_list(job_seekers_flow)
      limit -> Enum.take(job_seekers_flow, limit)
    end
  end

  defp build_geolocation(job_seeker) do
    geolocation = Vae.Places.get_geoloc_from_postal_code(job_seeker.postal_code)
    Map.put(job_seeker, :geolocation, geolocation)
  end

  defp build_job_seeker(line) do
    %{
      identifier: line["KN_INDIVIDU_NATIONAL"],
      first_name: String.capitalize(line["PRENOM"]),
      last_name: String.capitalize(line["NOM"]),
      email: line["COURRIEL"],
      telephone: line["TELEPHONE"],
      postal_code: line["CODE_POSTAL"],
      education_level: line["NIV_EN_FORMATION1_NUM"],
      experience:
        %{
          line["ROME1V3"] => map_xp_to_level(line["NROM1EXP"]),
          line["ROME2V3"] => map_xp_to_level(line["NROM2EXP"])
        }
        |> Map.delete("")
    }
  end

  defp map_xp_to_level(xp) do
    xp
    |> Float.parse()
    |> case do
      :error -> 0
      {level, _} -> level
    end
  end

  defp is_allowed_administrative?(job_seeker) do
    administrative =
      job_seeker
      |> get_in([:geolocation])
      |> Places.get_administrative()

    Enum.member?(@allowed_administratives, administrative)
  end
end

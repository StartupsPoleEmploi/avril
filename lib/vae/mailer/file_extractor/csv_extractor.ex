defmodule Vae.Mailer.FileExtractor.CsvExtractor do
  require Logger

  alias Vae.Places

  @behaviour Vae.Mailer.FileExtractor

  @limit Application.get_env(:vae, :mailer_extractor_limit)

  @fields ~w(KN_INDIVIDU_NATIONAL CODE_POSTAL TELEPHONE COURRIEL DATE_EFF_INS DC_LBLNIVEAUFORMATIONMAX NOM PRENOM DC_REFERENCEGMS DC_ROMEORE DN_DUREEEXPERIENCE DC_LISTEROMEMETIERRECH ANC AGE)

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
    "Nouvelle-Aquitaine",
    "Grand-Est",
    "Pays-de-la-Loire",
    "Normandie"
  ]

  def build_enumerable(path) do
    File.stream!(path)
    |> CSV.decode(separator: ?;, headers: true)
  end

  def extract_lines_flow(flow) do
    flow
    |> Flow.map(fn
      {:ok, line} -> Map.take(line, @fields)
      {:error, error} -> Logger.error(error)
    end)
  end

  def build_job_seeker_flow(flow) do
    flow |> Flow.map(&build_job_seeker/1)
  end

  def add_geolocation_flow(flow) do
    flow
    |> Flow.reduce(fn -> [] end, fn job_seeker, acc ->
      build_geolocation(job_seeker)
      |> is_allowed_administrative?()
      |> case do
        {:allowed, located_job_seeker} -> [located_job_seeker | acc]
        _ -> acc
      end
    end)
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
      education_level: line["DC_LBLNIVEAUFORMATIONMAX"],
      experience:
        line["DC_LISTEROMEMETIERRECH"]
        |> String.split(";")
        |> Enum.reduce(%{}, fn rome, acc ->
          Map.put_new(acc, rome, nil)
        end)
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

    if Enum.member?(@allowed_administratives, administrative) do
      {:allowed, job_seeker}
    else
      {:not_allowed, job_seeker}
    end
  end
end

defmodule Vae.CampaignDiffuser.FileExtractor.CsvExtractor do
  require Logger

  # @behaviour Vae.CampaignDiffuser.FileExtractor

  @fields ~w(
    kn_individu_national
    code_postal
    telephone
    courriel
    date_eff_ins
    listeformation
    nom
    prenom
    dc_referencegms
    dc_romeore
    dc_listeromemetierrech
    age
  )

  @allowed_administratives ~w(
    Bretagne
    Île-de-France
    Centre-Val de Loire
    Occitanie
    Bourgogne-Franche-Comté
    Provence-Alpes-Côte d'Azur
    Corse
    Hauts-de-France
    Auvergne-Rhône-Alpes
    Nouvelle-Aquitaine
    Grand-Est
    Pays-de-la-Loire
    Normandie
    Guadeloupe
  )

  def build_enumerable(type, from) do
    with {:ok, output_path} <- extract(type, from),
         stream <- File.stream!(output_path) do
      {
        :ok,
        stream
        |> CSV.decode(separator: ?;, headers: true)
      }
    else
      {:error, %{type: type}} ->
        {:error, type}
    end
  end

  def extract(type, from) do
    System.cmd("bunzip2", ["-kc", build_path(type, from)])
    |> case do
      {data, 0} ->
        output_path = "/tmp/emails_#{type}_#{Date.utc_today()}.csv"

        {
          File.write!(output_path, data),
          output_path
        }

      _ ->
        {:error, %{type: type}}
    end
  end

  def extract_lines_flow(flow) do
    flow
    |> Flow.map(fn
      {:ok, line} ->
        Map.take(line, @fields)

      {:error, error} ->
        Logger.error(error)
    end)
  end

  def build_job_seeker_flow(flow) do
    flow |> Flow.map(&build_job_seeker/1)
  end

  def add_geolocation_flow(flow) do
    flow
    |> Flow.reduce(fn -> [] end, fn job_seeker, acc ->
      [
        build_geolocation(job_seeker)
        | acc
      ]
    end)
  end

  def build_path(type, from) do
    "#{System.get_env("CAMPAIGN_BASE_PATH")}/avril_de_#{type}_delta_#{define_date(from)}1800.bz2"
  end

  def define_date(from) do
    Date.utc_today()
    |> Date.add(from * -1)
    |> Timex.format!("{YYYY}{0M}{0D}")
  end

  defp build_geolocation(job_seeker) do
    geolocation = Vae.Places.get_geoloc_from_postal_code(job_seeker.postal_code)
    Map.put(job_seeker, :geolocation, geolocation)
  end

  defp build_job_seeker(line) do
    %{
      identifier: line["kn_individu_national"],
      first_name: line["prenom"] |> String.trim() |> String.capitalize(),
      last_name: line["nom"] |> String.trim() |> String.capitalize(),
      email: clean_email(line["courriel"]),
      telephone: line["telephone"] |> String.trim(),
      postal_code: line["code_postal"] |> String.trim(),
      education_level: line["listeformation"],
      experience:
        line["dc_listeromemetierrech"]
        |> String.split("|")
        |> Enum.reduce(%{}, fn
          "", acc ->
            acc

          nil, acc ->
            acc

          rome, acc ->
            exp = String.split(rome, "-")
            Map.put_new(acc, List.first(exp), List.last(exp))
        end)
    }
  end

  def is_allowed_administrative?(job_seeker) do
    administrative =
      job_seeker
      |> get_in([:geolocation])
      |> Vae.Places.get_administrative()

    if Enum.member?(@allowed_administratives, administrative) do
      {:allowed, job_seeker}
    else
      {:not_allowed, job_seeker}
    end
  end

  defp clean_email(nil), do: nil

  defp clean_email(email) do
    email
    |> String.downcase()
    |> String.trim()
  end
end

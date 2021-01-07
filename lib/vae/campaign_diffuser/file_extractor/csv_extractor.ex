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

  def build_enumerable(type, date) do
    with {:ok, output_path} <- extract(type, date),
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

  def extract(type, date) do
    System.cmd("/bin/sh", ["-c", "bunzip2 -kc #{build_path(type, date)}"])
    |> case do
      {data, 0} ->
        output_path = "/tmp/emails_#{type}_#{date}.csv"

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

  def build_path(type, date) do
    "#{System.get_env("CAMPAIGN_BASE_PATH")}/avril_de_#{type}_delta_#{Timex.format!(date, "{YYYY}{0M}{0D}")}*.bz2"
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

  defp clean_email(nil), do: nil

  defp clean_email(email) do
    email
    |> String.downcase()
    |> String.trim()
  end
end

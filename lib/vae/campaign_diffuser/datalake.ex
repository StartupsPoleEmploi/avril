defmodule Vae.CampaignDiffuser.Datalake do
  require Logger
  alias Vae.{JobSeeker, Repo}
  alias VaeWeb.{JobSeekerEmail, Mailer}

  def process_both(date \\ nil) do
    process_primo_inscrits(date)
    process_reinscrits(date)
  end

  def process_primo_inscrits(date \\ nil), do:
    process(:primo_inscrits, date)

  def process_reinscrits(date \\ nil), do:
    process(:reinscrits, date)

  defp process(type, date \\ nil) when type in [:primo_inscrits, :reinscrits] do
    results = extract_zip(type, date || Vae.Date.last_monday())
    |> extract_csv()
    |> Enum.map(&handle_row(&1))

    Logger.info("#{length(results)} campaign mails sent")
  end

  defp handle_row({:ok, csv_row}) do
    job_seeker_data = build_job_seeker_data(csv_row)

    (Repo.get_by(JobSeeker, email: job_seeker_data.email) || %JobSeeker{})
    |> JobSeeker.changeset(job_seeker_data)
    |> Repo.insert_or_update()
    |> case do
      {:ok, %JobSeeker{} = job_seeker} ->
        job_seeker
        |> JobSeekerEmail.campaign()
        |> Mailer.send()
      {:error, error} -> Logger.error("Error: #{inspect(error)}")
    end
  end

  defp build_job_seeker_data(csv_row) do
    %{
      identifier: csv_row["kn_individu_national"],
      first_name: csv_row["prenom"] |> String.trim() |> String.capitalize(),
      last_name: csv_row["nom"] |> String.trim() |> String.capitalize(),
      email: csv_row["courriel"] |> String.trim() |> String.downcase(),
      telephone: csv_row["telephone"] |> String.trim(),
      postal_code: csv_row["code_postal"] |> String.trim(),
      education_level: csv_row["listeformation"],
      experience:
        csv_row["dc_listeromemetierrech"]
        |> String.split("|")
        |> Enum.reject(&(&1 in [nil, "", "NULL"]))
        |> Enum.reduce(%{}, fn
          rome, acc ->
            [key, _, value] = String.split(rome, "-", parts: 3)
            Map.put_new(acc, String.trim(key), String.trim(value))
        end)
    }
  end

  defp extract_zip(type, date) do
    case System.cmd("/bin/sh", ["-c", "bunzip2 -kc #{get_zip_path(type, date)}"]) do
      {data, 0} ->
        csv_path = get_csv_path(type, date)
        { File.write!(csv_path, data), csv_path}
      _ ->
        {:error, %{type: type}}
    end
  end

  defp extract_csv({:ok, csv_path}) do
    csv_path
    |> File.stream!()
    |> CSV.decode(separator: ?;, headers: true)
  end

  defp extract_csv({:error, _} = error), do: error

  defp get_csv_path(type, date), do: "/tmp/emails_#{type}_#{date}.csv"

  defp get_zip_path(type, date) do
    if System.get_env("CAMPAIGN_BASE_PATH") do
      "#{System.get_env("CAMPAIGN_BASE_PATH")}/avril_de_#{type}_delta_#{Timex.format!(date, "{YYYY}{0M}{0D}")}*.bz2"
    else
      # Debugging
      "priv/avril_de_#{type}_delta_#{Timex.format!(date, "{YYYY}{0M}{0D}")}*.bz2"
    end
  end

end
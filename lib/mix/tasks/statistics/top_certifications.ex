defmodule Mix.Tasks.Statistics.TopCertifications do
  require Logger

  use Mix.Task

  import Ecto.Query

  alias Vae.Application, as: JsApplication
  alias Vae.Certification
  alias Vae.JobSeeker
  alias Vae.Repo

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    job_seekers()
    |> extract_certifications_from_job_seekers()
    |> merge_with_applications()
    |> count()
    |> Enum.to_list()
    |> Enum.sort_by(&Kernel.elem(&1, 1), &>=/2)
    |> Enum.take(20)
  end

  def job_seekers() do
    sql = """
      SELECT
        DISTINCT email,
        id,
        identifier,
        first_name,
        last_name,
        telephone,
        postal_code,
        experience,
        education_level,
        events
      FROM job_seekers, jsonb_array_elements(events) AS e
      WHERE (e->>'time')::timestamp::date BETWEEN $1 AND $2
      AND (e->>'type') = 'contact_form'
      ORDER BY id DESC;
    """

    Ecto.Adapters.SQL.query!(Repo, sql, [~D[2019-01-01], Date.utc_today()])
  end

  def merge_with_applications(certifications) do
    from(a in JsApplication,
      join: c in Certification,
      on: c.id == a.certification_id,
      where: not is_nil(a.submitted_at),
      select: {c.acronym, c.label}
    )
    |> Repo.all()
    |> Enum.map(fn {acronym, label} ->
      String.downcase("#{acronym} #{label}")
    end)
    |> Kernel.++(certifications)
  end

  def extract_certifications_from_job_seekers(records) do
    records.rows
    |> Enum.map(&Repo.load(JobSeeker, {records.columns, &1}))
    |> Enum.flat_map(fn job_seeker ->
      job_seeker.events
      |> Enum.map(fn event ->
        event.payload
        |> Code.eval_string()
        |> Kernel.elem(0)
      end)
      |> Enum.filter(fn p ->
        p["contact_delegate"] == "on" and p["email"] != ""
      end)
      |> Enum.map(& &1["certification"])
    end)
  end

  def count(certifications) do
    Enum.reduce(certifications, %{}, fn
      nil, acc ->
        acc

      certification, acc ->
        Map.update(acc, String.downcase(certification), 1, &(&1 + 1))
    end)
  end
end

defmodule Mix.Tasks.Crm.StockReminder do
  require Logger
  use Mix.Task

  alias Vae.Repo
  alias Vae.JobSeeker
  alias VaeWeb.Mailer
  alias VaeWeb.JobSeekerEmail

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    job_seekers()
    |> build_records()
    |> build_emails()
    |> Mailer.send()
    |> (fn {:ok, emails} ->
          Logger.info(fn -> "stock_reminder: #{Kernel.length(emails)} emails sent" end)
        end).()
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
      ORDER BY id DESC;
    """

    Ecto.Adapters.SQL.query!(Repo, sql, [~D[2018-09-01], ~D[2019-03-31]])
  end

  def build_records(records) do
    records.rows
    |> Enum.map(&Repo.load(JobSeeker, {records.columns, &1}))
    |> Enum.filter(fn js ->
      not is_nil(js.events)
    end)
    |> Enum.reduce([], fn job_seeker, acc ->
      job_seeker.events
      |> Enum.reduce([], fn event, acc ->
        case event.payload do
          nil ->
            acc

          payload ->
            [
              payload
              |> Code.eval_string()
              |> Kernel.elem(0)
              | acc
            ]
        end
      end)
      |> Enum.filter(fn p ->
        p["contact_delegate"] == "on" and p["email"] != ""
      end)
      |> Enum.uniq_by(& &1["email"])
      |> case do
        [] ->
          acc

        [payload] ->
          [
            {job_seeker.id, payload}
            | acc
          ]

        true ->
          acc
      end
    end)
  end

  def build_emails(job_seekers) do
    job_seekers
    |> Enum.map(fn {_job_seeker_id, payload} ->
      JobSeekerEmail.stock(payload)
    end)
  end
end

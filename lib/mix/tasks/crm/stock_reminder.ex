defmodule Mix.Tasks.Crm.StockReminder do
  require Logger
  use Mix.Task

  alias Vae.Crm.Config
  alias Vae.JobSeeker
  alias Vae.Mailer.Email
  alias Vae.Repo

  @sender Application.get_env(:vae, :sender)

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:vae)

    job_seekers()
    |> build_records()
    |> build_emails()
    # |> send()
    |> Vae.Mailer.send()
    # |> (fn emails ->
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
    |> Enum.map(fn {job_seeker_id, payload} ->
      # %Email{
      #   custom_id: UUID.uuid5(nil, payload["email"]),
      #    to: %{Email: payload["email"], Name: "#{payload["first_name"]} #{payload["last_name"]}"},
      #   vars: %{
      #     job_seeker_id: job_seeker_id
      #   },
      #   template_id: Config.get_stock_template_id()
      # }
      Vae.Mailer.build_email(
        Config.get_stock_template_id(),
        :avril,
        to: %{Email: payload["email"], Name: "#{payload["first_name"]} #{payload["last_name"]}"},
        job_seeker_id: job_seeker_id
      )
    end)
  end

  def send(emails) do
    emails
    |> Enum.reduce([], fn email, acc ->
      case @sender.send(email) do
        [%Email{state: :success} = email] ->
          [email | acc]

        _ ->
          acc
      end
    end)
  end
end

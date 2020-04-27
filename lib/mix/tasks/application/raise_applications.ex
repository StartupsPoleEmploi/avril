defmodule Mix.Tasks.RaiseApplications do
  require Logger
  use Mix.Task

  import Ecto.Query

  alias VaeWeb.Mailer
  alias Vae.Repo

  alias Vae.UserApplication, as: AvrilApplication
  alias Vae.{Certification, Delegate, User}

  def run(_args) do
    Logger.info("Applicants wake up !")

    Mix.Task.run("app.start")

    with {:ok, emails} <- select_applications() do
      emails
      |> Flow.from_enumerable(window: Flow.Window.count(30))
      |> Flow.reduce(fn -> [] end, fn application, acc ->
        [
          build_deliver(application)
          | acc
        ]
      end)
      |> Flow.on_trigger(fn emails ->
        with {:ok, emails_sent} <- Mailer.send(emails) do
          Logger.info("#{length(emails_sent)} emails sent")
        else
          {:error, error} ->
            Logger.error(fn -> "Error while attempting to send emails: #{inspect(error)}" end)
        end

        {[], []}
      end)
      |> Flow.run()
    else
      msg ->
        Logger.error(fn -> "Unexpected error: #{msg}" end)
    end

    Logger.info("Thanks for your attention !")
  end

  def select_applications() do
    date = Date.utc_today() |> Date.add(-30)

    stream =
      from(a in AvrilApplication,
        join: u in User,
        on: a.user_id == u.id,
        join: d in Delegate,
        on: a.delegate_id == d.id,
        join: c in Certification,
        on: a.certification_id == c.id,
        where:
          fragment("?::date", a.submitted_at) < ^date and
            not is_nil(a.submitted_at) and
            is_nil(a.admissible_at)
      )
      |> Repo.stream()

    Repo.transaction(fn ->
      stream
      |> Repo.stream_preload(200, [:user, :delegate, :certification])
      |> Enum.to_list()
    end)
  end

  def build_deliver(application) do
    endpoint = Vae.URI.endpoint()

    application
    |> VaeWeb.ApplicationEmail.user_raise(endpoint)
  end
end

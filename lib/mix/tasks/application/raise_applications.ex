defmodule Mix.Tasks.RaiseApplications do
  require Logger
  use Mix.Task

  import Ecto.Query

  alias Vae.Mailer
  alias Vae.Repo

  alias Vae.Application, as: AvrilApplication
  alias Vae.{Certification, Delegate, User}

  def run(_args) do
    Logger.info("Applicants wake up !")

    Mix.Task.run("app.start")

    select_applications()

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
      |> Repo.stream_preload(20, [:user, :delegate, :certification])
      |> Stream.map(&build_deliver/1)
      |> Stream.scan([], fn application_email, acc ->
        case Mailer.send(application_email) do
          {:ok, _result} ->
            acc

          {:error, reason} ->
            Logger.error(fn -> inspect(reason) end)

            [
              application_email
              | acc
            ]
        end
      end)
      |> Enum.to_list()
    end)
  end

  def build_deliver(application) do
    path = %URI{
      scheme: "https",
      host: System.get_env("WHOST")
    }

    application
    |> Vae.ApplicationEmail.user_raise(path)
  end
end

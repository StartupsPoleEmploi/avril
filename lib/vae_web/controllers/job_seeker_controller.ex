defmodule VaeWeb.JobSeekerController do
  use VaeWeb, :controller

  alias Vae.Repo
  alias Vae.UserApplications.Polls
  alias Vae.{Certification, Delegate, Event, JobSeeker}
  alias VaeWeb.JobSeekerEmail
  alias VaeWeb.Mailer

  def create(conn, %{
        "job_seeker" => %{
          "email" => email,
          "certification_id" => certification_id,
          "delegate_id" => delegate_id
        }
      }) do
    with(
      email when email != "" <- email,
      delegate when not is_nil(delegate) <- Repo.get(Delegate, delegate_id),
      certification when not is_nil(certification) <- Repo.get(Certification, certification_id),
      job_seeker when not is_nil(job_seeker) <-
        Event.create_or_update_job_seeker(%{
          email: email,
          type: "receive_synthesis",
          event: "submitted",
          delegate_id: delegate.id,
          certification_id: certification.id
        })
    ) do
      {:ok, _pid} =
        Task.start(fn ->
          JobSeekerEmail.receive_synthesis(job_seeker, delegate)
          |> Mailer.send()
        end)

      conn
      |> put_flash(:info, "Vous allez recevoir votre synthèse d'un instant à l'autre.")
      |> redirect(
        to:
          Routes.certification_path(
            conn,
            :show,
            certification_id,
            certificateur: delegate.id
          )
      )
    else
      _ ->
        conn
        |> put_flash(:danger, "Une erreur est survenue, merci de réessayer plus tard.")
        |> redirect(
          to:
            Routes.certification_path(
              conn,
              :show,
              certification_id,
              certificateur: delegate_id
            )
        )
    end
  end

  def admissible(conn, %{"id" => id}) do
    Repo.get(JobSeeker, id)
    |> JobSeeker.admissible()
    |> Repo.update!()

    conn
    |> put_flash(:success, "Merci pour votre réponse")
    |> redirect(to: Routes.root_path(conn, :index))
  end

  def inadmissible(conn, %{"id" => id}) do
    Repo.get(JobSeeker, id)
    |> JobSeeker.inadmissible()
    |> Repo.update!()

    conn
    |> redirect(external: Polls.get_default_stock_form_url() || Routes.root_path(conn, :index))
  end
end

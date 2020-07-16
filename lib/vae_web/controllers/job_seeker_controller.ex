defmodule VaeWeb.JobSeekerController do
  use VaeWeb, :controller

  alias Vae.Repo
  alias Vae.UserApplications.Polls
  alias Vae.{Certification, Delegate, Event, JobSeeker}
  alias VaeWeb.JobSeekerEmail
  alias VaeWeb.Mailer

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

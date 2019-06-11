defmodule Vae.JobSeekerController do
  use Vae.Web, :controller

  alias Vae.JobSeeker
  alias Vae.Crm.Polls

  def admissible(conn, %{"id" => id} = params) do
    Repo.get(JobSeeker, id)
    |> JobSeeker.admissible()
    |> Repo.update!()

    conn
    |> put_flash(:success, "Merci pour votre réponse")
    |> redirect(to: Routes.root_path(conn, :index))
  end

  def inadmissible(conn, %{"id" => id} = params) do
    Repo.get(JobSeeker, id)
    |> JobSeeker.inadmissible()
    |> Repo.update!()

    conn
    |> redirect(external: Polls.get_default_stock_form_url())
  end
end

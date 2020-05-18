defmodule VaeWeb.UserApplication.ResumeController do
  require Logger
  use VaeWeb, :controller

  plug(VaeWeb.Plugs.ApplicationAccess)

  alias Vae.{Resume}

  def delete(conn, %{"id" => id}) do
    resume = Repo.get(Resume, id)

    case Resume.delete(resume) do
      {:ok, _resume} ->
        conn
        |> put_flash(:success, "CV supprimé avec succès.")
        |> redirect(to: Routes.admin_resource_path(conn, :index, :resumes))

      {:error, _msg} ->
        conn
        |> put_flash(:danger, "Le CV n'a pas pu être supprimé, merci de réessayer plus tard.")
        |> redirect(to: Routes.admin_resource_path(conn, :index, Resume))
    end
  end
end

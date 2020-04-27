defmodule VaeWeb.UserApplication.ResumeController do
  require Logger
  use VaeWeb, :controller

  plug(VaeWeb.Plugs.ApplicationAccess)

  alias Vae.{Resume}

  def create(conn, params) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user])

    if resume_params = params["resume"]["file"] do
      case Resume.create(application, resume_params, conn) do
        {:ok, _resume} ->
          conn
          |> put_flash(:success, "CV uploadé avec succès.")
          |> redirect_back(default: Routes.user_application_path(conn, :show, application))

        {:error, msg} ->
          conn
          |> put_flash(:danger, msg)
          |> redirect_back(default: Routes.user_application_path(conn, :show, application))
      end
    else
      conn
      |> put_flash(:warning, "Vous n'avez pas sélectionné de fichier.")
      |> redirect_back(default: Routes.user_application_path(conn, :show, application))
    end
  end

  def delete(conn, %{"id" => id}) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user])

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

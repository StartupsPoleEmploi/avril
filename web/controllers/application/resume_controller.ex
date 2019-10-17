defmodule Vae.ResumeController do
  require Logger
  use Vae.Web, :controller
  plug(Vae.Plugs.ApplicationAccess)

  alias Vae.{Resume}

  def create(conn, %{"application_id" => _application_id, "resume" => resume_params}) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user])

    if params = resume_params["file"] do
      case Resume.create(application, params) do
        {:ok, _resume} ->
          conn
          |> put_flash(:success, "CV uploadé avec succès.")
          |> redirect_back(default: Routes.application_path(conn, :show, application))

        {:error, msg} ->
          conn
          |> put_flash(:error, msg)
          |> redirect_back(default: Routes.application_path(conn, :show, application))
      end
    end
  end

  def delete(conn, %{"application_id" => _application_id, "id" => id}) do
    application =
      conn.assigns[:current_application]
      |> Repo.preload([:user])

    resume = Repo.get(Resume, id)

    case Resume.delete(resume) do
      {:ok, _resume} ->
        conn
        |> put_flash(:success, "CV supprimé avec succès.")
        |> redirect_back(default: Routes.application_path(conn, :show, application))

      {:error, _msg} ->
        conn
        |> put_flash(:error, "Le CV n'a pas pu être supprimé, merci de réessayer plus tard.")
        |> redirect_back(default: Routes.application_path(conn, :show, application))
    end
  end
end

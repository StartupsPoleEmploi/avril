defmodule Vae.ResumeController do
  require Logger
  use Vae.Web, :controller
  # plug Coherence.Authentication.Session, protected: true

  alias Vae.{Application, Delegate, User, Resume}
  alias Vae.Crm.Polls

  def create(conn, %{"application_id" => id, "resume" => resume_params}) do
    application =
      case Repo.get(Application, id) do
        nil -> nil
        application -> Repo.preload(application, [:user])
      end

    case Vae.ApplicationController.has_access?(conn, application, nil) do
      {:ok, application} ->
        if params = resume_params["file"] do
          case Resume.create(application, params) do
            {:ok, resume} ->
              conn
              |> put_flash(:success, "CV uploadé avec succès.")
              |> redirect(to: Routes.application_path(conn, :show, application))
            {:error, msg} ->
              conn
              |> put_flash(:error, msg)
              |> redirect(to: Routes.application_path(conn, :show, application))
          end
        end

      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end

  def delete(conn, %{"application_id" => application_id, "id" => id}) do
    application =
      case Repo.get(Application, application_id) do
        nil -> nil
        application -> Repo.preload(application, [:user])
      end

    case Vae.ApplicationController.has_access?(conn, application, nil) do
      {:ok, application} ->
        resume = Repo.get(Resume, id)
        case Resume.delete(resume) do
          {:ok, _resume} ->
            conn
            |> put_flash(:success, "CV supprimé avec succès.")
            |> redirect(to: Routes.application_path(conn, :show, application))
          {:error, _msg} ->
            conn
            |> put_flash(:error, "Le CV n'a pas pu être supprimé, merci de réessayer plus tard.")
            |> redirect(to: Routes.application_path(conn, :show, application))
        end

      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end
end

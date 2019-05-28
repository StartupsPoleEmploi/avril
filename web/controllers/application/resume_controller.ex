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
        if file = resume_params["file"] do
          new_filename = "#{application.id}-resume-#{Vae.String.parameterize(application.user.name)}#{Path.extname(file.filename)}"
          case File.cp(file.path, "/media/vae/#{new_filename}") do
            :ok ->
              changeset = Resume.changeset(%Resume{}, %{
                content_type: file.content_type,
                filename: new_filename,
                application: application,
              })
              case Repo.insert(changeset) do
                {:ok, resume} ->
                  conn
                  |> put_flash(:success, "CV uploadé avec succès.")
                  |> redirect(to: application_path(conn, :show, application))
                {:error, msg} ->
                  conn
                  |> put_flash(:error, msg)
                  |> redirect(to: application_path(conn, :show, application))
              end
            {:error, :enoent} ->
              conn
              |> put_flash(:error, "Le fichier n'a pas pu être enregistrer. Merci de réessayer plus tard ou de nous contacter.")
              |> redirect(to: application_path(conn, :show, application))
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
        case Repo.delete(resume) do
          {:ok, _resume} ->
            conn
            |> put_flash(:success, "CV supprimé avec succès.")
            |> redirect(to: application_path(conn, :show, application))
          {:error, _msg} ->
            conn
            |> put_flash(:error, "Le CV n'a pas pu être supprimé, merci de réessayer plus tard.")
            |> redirect(to: application_path(conn, :show, application))
        end

      {:error, %{to: to, msg: msg}} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: to)
    end
  end
end

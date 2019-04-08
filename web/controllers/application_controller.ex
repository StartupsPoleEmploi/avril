defmodule Vae.ApplicationController do
  require Logger
  use Vae.Web, :controller
  # plug Coherence.Authentication.Session, protected: true

  alias Vae.User
  alias Vae.Application

  def show(conn, %{"id" => id} = params) do
    application = case Repo.get(Application, id) do
      nil -> nil
      application -> Repo.preload(application, [:user, :delegate, :certification])
    end

    case has_access?(conn, application, params["hash"]) do
      {:ok, application} ->
        render(conn, "show.html",
          application: application,
          delegate: application.delegate,
          certification: application.certification,
          user: application.user,
          edit_mode: Coherence.current_user(conn).id == application.user.id,
          changeset: User.changeset(application.user, %{})
        )
      {:error, error_msg} ->
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: root_path(conn, :index))
    end
  end

  # TODO: change to submit
  def update(conn, %{"id" => id}) do
    application = case Repo.get(Application, id) do
      nil -> nil
      application -> Repo.preload(application, [:user, :delegate, :certification])
    end

    case has_access?(conn, application, nil) do
      {:ok, application} ->
        case Application.submit(application) do
          {:ok, application} ->
            conn
            |> put_flash(:success, "Dossier transmis avec succès!")
            |> redirect(to: application_path(conn, :show, application))
          {:error, changeset} ->
            conn
            |> put_flash(:error, "Une erreur est survenue, n'hésitez pas à nous contacter pour plus d'infos")
            |> redirect(to: application_path(conn, :show, application))
        end
      {:error, error_msg} ->
        conn
        |> put_flash(:error, error_msg)
        |> redirect(to: root_path(conn, :index))
    end

  end

  defp has_access?(conn, application, nil) do
    if not is_nil(application) && not is_nil(Coherence.current_user(conn)) && Coherence.current_user(conn).id == application.user.id do
      {:ok, application}
    else
      {:error, "Vous n'avez pas accès."}
    end
  end

  defp has_access?(conn, application, hash) do
    if not is_nil(application) &&
      application.delegate_access_hash == hash &&
      Timex.before?(Timex.today, Timex.shift(application.delegate_access_refreshed_at, days: 10)) do
      {:ok, application}
    else
      {:error, (if application.delegate_access_hash == hash, do: "Accès expiré", else: "Vous n'avez pas accès") }
    end
  end

end

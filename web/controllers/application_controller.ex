defmodule Vae.ApplicationController do
  require Logger
  use Vae.Web, :controller
  # plug Coherence.Authentication.Session, protected: true

  alias Vae.User
  alias Vae.Application

  def show(conn, %{"id" => id}) do
    application = Repo.get(Application, id)
    |> Repo.preload([:user, :delegate, :certification])

    if !is_nil(application) && Coherence.current_user(conn).id == application.user.id do
      render(conn, "show.html",
        application: application,
        delegate: application.delegate,
        certification: application.certification,
        user: application.user,
        edit_mode: Coherence.current_user(conn).id == application.user.id,
        changeset: User.changeset(application.user, %{})
      )
    else
      conn
      |> put_flash(:error, "Vous n'avez pas accès.")
      |> redirect(to: root_path(conn, :index))
    end
  end

  # TODO: change to submit
  def update(conn, %{"id" => id}) do
    application = Repo.get(Application, id)
    |> Repo.preload([:user])

    # TODO: refacto check at controller level
    if !is_nil(application) && Coherence.current_user(conn).id == application.user.id do
      Application.generate_delegate_access(application)
      ##################
      # TODO: send mail
      ##################
      changeset = Application.changeset(application, %{submitted_at:  DateTime.utc_now()})
      case Repo.update(changeset) do
        {:ok, application} ->
          conn
          |> put_flash(:success, "Dossier transmis avec succès!")
          |> redirect(to: application_path(conn, :show, application))
        {:error, changeset} ->
          conn
          |> put_flash(:error, "Une erreur est survenue, n'hésitez pas à nous contacter pour plus d'infos")
          |> redirect(to: application_path(conn, :show, application))
      end
    else
      conn
      |> put_flash(:error, "Vous n'avez pas accès.")
      |> redirect(to: root_path(conn, :index))
    end

  end

end

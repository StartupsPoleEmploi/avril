defmodule VaeWeb.RegistrationController do
  require Logger
  use VaeWeb, :controller

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, _user, conn} ->
        conn
        |> maybe_make_session_persistent(user_params)
        |> maybe_create_application_and_redirect()

      {:error, changeset, conn} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def maybe_make_session_persistent(conn, %{"persistent_session" => "true"}) do
    PowPersistentSession.Plug.create(conn, Pow.Plug.current_user(conn))
  end

  def maybe_make_session_persistent(conn, _user_params) do
    PowPersistentSession.Plug.delete(conn)
  end

  def maybe_create_application_and_redirect(conn, certification_id \\ nil) do
    with(
      current_user when not is_nil(current_user) <- Pow.Plug.current_user(conn),
      certification_id when not is_nil(certification_id) <-
        certification_id || Plug.Conn.get_session(conn, :certification_id),
      {:ok, application} <-
        Vae.UserApplication.find_or_create_with_params(%{
          user_id: current_user.id,
          certification_id: certification_id
        })
    ) do
      Plug.Conn.delete_session(conn, :certification_id)
      |> redirect_to_user_space(application)
    else
      error ->
        redirect_to_user_space(conn)
    end
  end

  defp redirect_to_user_space(conn, application \\ nil) do
    if Pow.Plug.current_user(conn) do
      redirect(conn, external: Vae.User.profile_url(conn, application))
    else
      redirect(conn, to: Routes.signup_path(conn, :new))
    end
  end

end
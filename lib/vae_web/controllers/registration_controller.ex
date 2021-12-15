defmodule VaeWeb.RegistrationController do
  require Logger
  use VaeWeb, :controller

  alias Vae.{Delegate, User}

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, current_user, conn} ->
        if Repo.exists?(from d in Delegate, where: [email: ^current_user.email]) do
          send_delegate_access_confirmation_email(conn, current_user)
        else
          maybe_create_application_and_redirect(conn)
        end

      {:error, changeset, conn} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp send_delegate_access_confirmation_email(conn, current_user) do
    VaeWeb.UserEmail.activate_delegate_access(current_user, conn)
    |> VaeWeb.Mailer.send()

    conn
    |> put_flash(:info, "Un email vient de vous être envoyé afin d'activer votre espace certificateur. Merci de vérifier votre boîte de réception.")
    |> redirect(to: Routes.root_path(conn, :index))
  end

  def maybe_create_application_and_redirect(conn) do
    conn = with(
      current_user when not is_nil(current_user) <- Pow.Plug.current_user(conn),
      certification_id when not is_nil(certification_id) <- conn.assigns[:certification_id],
      {:ok, application} when not is_nil(application) <-
        Vae.UserApplication.find_or_create_with_params(%{
          user_id: current_user.id,
          certification_id: certification_id
        })
    ) do
      Plug.Conn.assign(conn, :current_application, application)
    else
      _error -> conn
    end
    redirect(conn, external: get_after_signup_path(conn))
  end

  def get_after_signup_path(conn) do
    case Pow.Plug.current_user(conn) do
      %User{is_delegate: true} -> Routes.delegate_authenticated_path(conn, :index)
      %User{} -> Vae.User.profile_url(conn, conn.assigns[:current_application])
      _ -> Routes.signup_path(conn, :new)
    end
  end
end
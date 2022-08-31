defmodule VaeWeb.RegistrationController do
  require Logger
  use VaeWeb, :controller

  alias Vae.{User}

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, current_user, conn} ->
        if User.delegatable?(current_user) do
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
    current_user = Pow.Plug.current_user(conn)
    certification_id = Plug.Conn.get_session(conn, :certification_id)
    transferable_applications = User.transferable_applications(current_user)

    if certification_id && length(transferable_applications) > 0 do
      redirect(conn, to: Routes.certification_path(conn, :show, certification_id, transferable: ""))
    else
      conn = with(
        %User{id: user_id} <- current_user,
        certification_id when not is_nil(certification_id) <- certification_id,
        {:ok, application} when not is_nil(application) <-
          Vae.UserApplication.find_or_create_with_params(%{
            user_id: user_id,
            certification_id: certification_id
          })
      ) do
        conn
        |> Plug.Conn.delete_session(:certification_id)
        |> Plug.Conn.assign(:current_application, application)
      else
        _error -> conn
      end
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
defmodule VaeWeb.ResetPasswordController do
  use VaeWeb, :controller

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> PowResetPassword.Plug.create_reset_token(user_params)
    |> case do
      {:ok, %{token: token, user: user}, conn} ->
        # Send e-mail

        conn
        |> put_flash(:info, "Un email vous a été envoyé. Allez vérifier votre boîte de réception")
        |> redirect(to: Routes.reset_password_path(conn, :new))

      {:error, conn} ->
        conn
        |> put_flash(:info, "Un email vous a été envoyé. Allez vérifier votre boîte de réception")
        |> redirect(to: Routes.reset_password_path(conn, :new))
    end
  end

  def update(conn, %{"user" => user_params}) do

    PowResetPassword.Plug.update_user_password(conn, user_params)
    # {:ok, conn} = Pow.Plug.clear_authenticated_user(conn)

    redirect(conn, to: Routes.login_path(conn, :new))
  end
end


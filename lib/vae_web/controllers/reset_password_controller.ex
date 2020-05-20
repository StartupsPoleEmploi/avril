defmodule VaeWeb.ResetPasswordController do
  use VaeWeb, :controller

  plug :load_user_from_reset_token when action in [:edit, :update]

  def new(conn, _params) do
    changeset = Pow.Plug.change_user(conn)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    conn
    |> PowResetPassword.Plug.create_reset_token(user_params)
    |> case do
      {:ok, %{token: token, user: user}, conn} ->
        VaeWeb.UserEmail.reset_password(user, token)
        |> VaeWeb.Mailer.send()

        redirect_to_home(conn)

      {:error, error_changeset, conn} ->
        redirect_to_home(conn)
    end
  end

  def edit(conn, %{"id" => token}) do
    changeset = Pow.Plug.change_user(conn)
    render(conn, "edit.html", changeset: changeset, token: token)
  end

  def update(conn, %{"id" => token, "user" => user_params}) do
    case PowResetPassword.Plug.update_user_password(conn, user_params) do
      {:ok, _user, conn} ->
        conn
        |> put_flash(
          :info,
          "Votre mot de passe a bien été mis à jour, vous pouvez vous connecter."
        )
        |> redirect(to: Routes.login_path(conn, :new))

      {:error, changeset, conn} ->
        conn
        |> render("edit.html", changeset: changeset, token: token)
    end
  end

  defp redirect_to_home(conn) do
    conn
    |> put_flash(
      :info,
      "Un email vous a été envoyé. Nous vous invitons à consulter votre boîte de réception."
    )
    |> redirect(to: Routes.root_path(conn, :index))
  end

  defp load_user_from_reset_token(%{params: %{"id" => token}} = conn, _opts) do
    case PowResetPassword.Plug.load_user_by_token(conn, token) do
      {:error, conn} ->
        conn
        |> put_flash(
          :error,
          "Le lien que vous avez cliqué n'est pas valide. Merci de réinitialiser à nouveau votre mot de passe."
        )
        |> redirect(to: Routes.reset_password_path(conn, :new))
        |> halt()

      {:ok, conn} ->
        conn
    end
  end
end

defmodule VaeWeb.Plugs.CheckIsDelegate do
  import Phoenix.Controller
  import Plug.Conn
  alias VaeWeb.Router.Helpers, as: Routes
  alias Vae.User

  def init(opts), do: opts

  def call(conn, _opts) do
    IO.inspect(Pow.Plug.current_user(conn))
    case Pow.Plug.current_user(conn) do
      %User{is_delegate: is_delegate, is_admin: is_admin} when is_delegate or is_admin -> conn
      %User{} ->
        conn
        |> put_flash(:danger, "Vous n'avez pas accès.")
        |> redirect(to: Routes.root_path(conn, :index))
      _ -> halt(conn)
    end
  end
end
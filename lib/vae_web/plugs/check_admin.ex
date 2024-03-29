defmodule VaeWeb.Plugs.CheckAdmin do
  import Phoenix.Controller
  import Plug.Conn
  alias VaeWeb.Router.Helpers, as: Routes
  alias Vae.User

  def init(opts), do: opts

  def call(conn, _opts) do
    case Pow.Plug.current_user(conn) do
      %User{is_admin: true} -> conn
      %User{} ->
        conn
        |> put_flash(:danger, "Vous n'avez pas accès.")
        |> redirect(to: Routes.root_path(conn, :index))
      _ -> halt(conn)
    end
  end
end
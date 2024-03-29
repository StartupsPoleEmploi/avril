defmodule VaeWeb.Controllers.Helpers do
  def redirect_back(conn, opts \\ []) do
    referer = Plug.Conn.get_req_header(conn, "referer") |> List.first()

    Phoenix.Controller.redirect(conn,
      external: referer || opts[:default] || VaeWeb.Router.Helpers.root_path(conn, :index)
    )
  end

  def sync_user(conn, user), do: Pow.Plug.create(conn, user)
end

defmodule Vae.Controllers.Helpers do
  def redirect_back(conn, opts \\ []) do
    referer = Plug.Conn.get_req_header(conn, "referer") |> List.first
    Phoenix.Controller.redirect(conn, external: referer || opts[:default] || Vae.Router.Helpers.root_path(conn, :index))
  end
end
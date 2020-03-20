defmodule VaeWeb.Controllers.Helpers do
  def redirect_back(conn, opts \\ []) do
    referer = Plug.Conn.get_req_header(conn, "referer") |> List.first()

    Phoenix.Controller.redirect(conn,
      external: referer || opts[:default] || VaeWeb.Router.Helpers.root_path(conn, :index)
    )
  end

  def certification_and_delegate_from_path(path) do
    case Regex.named_captures(
           ~r/\/diplomes\/(?<certification_id>\d+)[0-9a-z\-]*\?certificateur=(?<delegate_id>\d+)[0-9a-z\-]*/,
           path
         ) do
      nil ->
        nil

      capture ->
        capture
        |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), String.to_integer(v)} end)
    end
  end
end

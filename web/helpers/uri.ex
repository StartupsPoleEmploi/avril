defmodule Vae.URI do

  def conn_or_endpoint_to_uri(endpoint) when is_atom(endpoint) do
    endpoint.url() |> URI.parse()
  end
  def conn_or_endpoint_to_uri(%Plug.Conn{} = conn) do
    Phoenix.Controller.current_url(conn) |> URI.parse()
  end
end
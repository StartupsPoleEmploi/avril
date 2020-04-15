defmodule Vae.URI do
  require Logger

  def to_absolute_string(%URI{} = query_path, %URI{} = base) do
    Map.merge(base, query_path, fn
      _k, nil, v -> v
      _k, v, nil -> v
      _k, _v1, v2 -> v2
    end)
    |> URI.to_string()
  end

  def to_absolute_string(%URI{} = query_path, endpoint) do
    to_uri(endpoint)
    |> URI.merge(query_path)
    |> URI.to_string()
  end

  def to_absolute_string(_query_path, _endpoint) do
    raise ArgumentError, "you must provide a query path URI and an Endpoint or Plug.Conn"
  end

  defp to_uri(endpoint) when is_atom(endpoint) do
    endpoint.url() |> URI.parse()
  end

  defp to_uri(%Plug.Conn{} = conn) do
    Phoenix.Controller.current_url(conn) |> URI.parse()
  end
end
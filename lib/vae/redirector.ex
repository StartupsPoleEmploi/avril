defmodule Vae.Redirector do
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  @spec init(Keyword.t) :: Keyword.t
  def init(options) do
    if Keyword.get(options, :to) do
      options
    else
      raise("Missing required to: option in redirect")
    end
  end

  @spec call(Plug.Conn.t, Keyword.t) :: Plug.Conn.t
  def call(conn, options) do
    to = Keyword.get(options, :to)
    if String.starts_with?(to, "http") do
      external = to
      |> URI.parse
      |> URI.to_string

      redirect(conn, external: external)
    else
      msg = Keyword.get(options, :msg)
      (if msg, do: put_flash(conn, :info, msg), else: conn)
      |> redirect(to: reinject_params(to, conn.path_params))
    end
  end

  defp reinject_params(to, params) do
    Regex.replace(~r/:([a-z_-]+)/, to, fn _, x -> params[x] end)
  end
end


defmodule Vae.Redirector do
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  @spec init(Keyword.t()) :: Keyword.t()
  def init([to: _] = opts), do: opts
  def init([external: _] = opts), do: opts
  def init(_default), do: raise("Missing required to: / external: option in redirect")

  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, options) do
    %{to: to, flash: flash} =
      Enum.into(options, %{
        flash: %{
          level: :info,
          msg: "La page demandée n'existe plus. Veuillez démarrer une nouvelle recherche."
        }
      })

    conn
    |> put_flash(flash[:level], flash[:msg])
    |> redirect(to: to)
  end

  def call(conn, external: url) do
    external =
      url
      |> URI.parse()
      |> URI.to_string()

    redirect(conn, external: external)
  end
end

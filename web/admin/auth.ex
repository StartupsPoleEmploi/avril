defmodule Vae.CheckAdmin do
  import Phoenix.Controller
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = Coherence.current_user(conn)

    if current_user do
      if current_user.is_admin do
        conn
      else
        conn
        |> put_flash(:error, "Vous n'avez pas accès.")
        |> redirect(to: "/")
      end
    else
      halt(conn)
    end
  end
end
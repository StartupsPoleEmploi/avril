defmodule VaeWeb.DelegateAuthenticatedController do
  use VaeWeb, :controller

  alias Vae.Delegate

  def my_applications(conn, params) do
    render(conn, "mes_candidatures.html")
  end
end
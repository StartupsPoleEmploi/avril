defmodule Vae.Api.ProfileController do
  use Vae.Web, :controller

  def index(conn, params) do
    json(conn, %{
      status: :ok,
      data: "coucou"
    })
  end
end

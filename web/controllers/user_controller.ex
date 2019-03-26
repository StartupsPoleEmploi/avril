defmodule Vae.UserController do
  require Logger
  use Vae.Web, :controller
  plug Coherence.Authentication.Session, protected: true

  alias Vae.User

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)
    render(conn, "show.html", user: user, layout: {Vae.LayoutView, "home-white.html"})
  end
end

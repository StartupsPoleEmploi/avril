defmodule Vae.CertifierController do
  use Vae.Web, :controller

  alias Vae.Certifier

  def index(conn, _params) do
    certifiers = Repo.all(Certifier)
    render(conn, "index.html", certifiers: certifiers)
  end

  def show(conn, %{"id" => id}) do
    certifier = Repo.get!(Certifier, id)
    render(conn, "show.html", certifier: certifier)
  end

  def delegates(conn, %{"id" => id}) do
    delegates = Repo.get!(Certifier, id)
    |> assoc(:delegates)
    |> Repo.all

    render(conn, Vae.DelegateView, :index, delegates: delegates)
  end
end

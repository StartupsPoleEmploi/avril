defmodule Vae.RomeController do
  use Vae.Web, :controller

  alias Vae.Rome

  def index(conn, _params) do
    romes = Repo.all(Rome)
    render(conn, "index.html", romes: romes)
  end

  def show(conn, %{"id" => id}) do
    rome = Repo.get!(Rome, id)
    render(conn, "show.html", rome: rome)
  end

  def certifications(conn, params) do
    rome = Repo.get!(Rome, params["id"])
    page = rome
           |> assoc(:certifications)
           |> order_by(desc: :level)
           |> preload(:delegates)
           |> Repo.paginate(params)

    update_wizard_trails(conn, step: 2, url: "/romes/#{params["id"]}/certifications")
    |> render(Vae.CertificationView, "index.html", certifications: page.entries, page: page, rome: rome, profession: params["search"]["profession"] || rome.label)
  end

end

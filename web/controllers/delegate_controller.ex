defmodule Vae.DelegateController do
  use Vae.Web, :controller

  alias Vae.Delegate
  alias Vae.Certification

  def index(conn, params) do
    page = Delegate
    |> where(is_active: true)
    |> order_by(asc: :name)
    |> Repo.paginate(params)

    render(conn, "index.html", delegates: page.entries, page: page)
  end

  def show(conn, %{"id" => id, "certification" => certification_id}) do
    certification = Repo.get!(Certification, certification_id)
    render_result(conn, id, certification)
  end

  def show(conn, %{"id" => id}) do
    render_result(conn, id, nil)
  end

  defp render_result(conn, id, certification) do
    delegate = Repo.get!(Delegate, id)
               |> Repo.preload(:process)

    update_wizard_trails(conn, step: 4, url: "delegates/#{id}")
    |> render("show.html", delegate: delegate, certification: certification)
  end

end

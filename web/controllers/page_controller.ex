defmodule Vae.PageController do
  use Vae.Web, :controller

  alias Vae.Certification

  def index(conn, _params) do
    top_certifications = Certification
                         |> Certification.top_three
                         |> Repo.all
    render conn, "index.html", layout: {Vae.LayoutView, "home.html"}, top_certifications: top_certifications
  end

  def vae(conn, _params) do
    render conn, "vae.html"
  end

  def terms_of_use(conn, _params) do
    render conn, "terms_of_use.html"
  end
end

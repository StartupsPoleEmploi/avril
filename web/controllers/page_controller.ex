defmodule Vae.PageController do
  use Vae.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html", layout: {Vae.LayoutView, "home.html"})
  end

  def vae(conn, _params) do
    render(conn, "vae.html", layout: {Vae.LayoutView, "home-white.html"})
  end

  def terms_of_use(conn, _params) do
    render(conn, "terms_of_use.html", layout: {Vae.LayoutView, "home-white.html"})
  end

  def choose_certification(conn, _params) do
    render(conn, "choose-certification.html", layout: {Vae.LayoutView, "home-white.html"})
  end

  def accessibility_promess(conn, _params) do
    render(conn, "accessibility-promess.html", layout: {Vae.LayoutView, "home-white.html"})
  end

  def point_relais_conseil(conn, _params) do
    render(conn, "point-relais-conseil.html", layout: {Vae.LayoutView, "home-white.html"})
  end

  def certificateur_vae_definition(conn, _params) do
    render(conn, "certificateur-vae-definition.html", layout: {Vae.LayoutView, "landing-extend.html"})
  end
end

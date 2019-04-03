defmodule Vae.PageController do
  use Vae.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html",
      no_container: true,
      body_class: 'home'
    )
  end

  def vae(conn, _params) do
    render(conn, "vae.html",
      body_class: 'home-white'
    )
  end

  def terms_of_use(conn, _params) do
    render(conn, "terms_of_use.html",
      body_class: 'home-white'
    )
  end

  def choose_certification(conn, _params) do
    render(conn, "choose-certification.html",
      body_class: 'home-white'
    )
  end

  def accessibility_promess(conn, _params) do
    render(conn, "accessibility-promess.html",
      body_class: 'home-white'
    )
  end

  def point_relais_conseil(conn, _params) do
    render(conn, "point-relais-conseil.html",
      body_class: 'home-white'
    )
  end

  def certificateur_vae_definition(conn, _params) do
    render(conn, "certificateur-vae-definition.html",
      body_class: 'landing-extend'
    )
  end

  def pourquoi_une_certification(conn, _params) do
    render(conn, "pourquoi-une-certification.html",
      body_class: 'landing-extend'
    )
  end

  def stats(conn, _params) do
    redirect(conn, external: "https://datastudio.google.com/u/0/reporting/1t7iUT7wGQn9U7ODZeDyXIvIRlK-BJAZs/page/1M")
  end
end

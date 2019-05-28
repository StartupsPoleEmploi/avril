defmodule Vae.PageController do
  use Vae.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html",
      title: "Comment faire une VAE ?",
      no_container: true,
      body_class: 'home'
    )
  end

  def vae(conn, _params) do
    render(conn, "vae.html",
      title: "Qu'est-ce que la VAE ?",
      description: "Comprendre comment obtenir un diplôme en Validation des Acquis d'Expérience (VAE), son dossier de candidature et d'expérience et son oral.",
      body_class: 'home-white'
    )
  end

  def terms_of_use(conn, _params) do
    render(conn, "terms_of_use.html",
      title: "Conditions générales d’utilisation",
      description: "Comme toute plateforme web, Avril inclue aussi des conditions générale d'utilisation.",
      body_class: 'home-white'
    )
  end

  def choose_certification(conn, _params) do
    render(conn, "choose-certification.html",
      title: "Comment bien choisir son diplôme ?",
      description: "Pas évident de savoir à quel diplôme prétendre lorsqu'on se lance dans une VAE. Heureusement Avril va vous aider dans chacune des étapes du processus, et le choix du diplôme en fait partie.",
      body_class: 'home-white'
    )
  end

  def accessibility_promess(conn, _params) do
    render(conn, "accessibility-promess.html",
      title: "Avril et l'accessibilité",
      description: "Avril, service de Pôle-emploi, s'engage pour être accessible à tous les publics.",
      body_class: 'home-white'
    )
  end

  def point_relais_conseil(conn, _params) do
    render(conn, "point-relais-conseil.html",
      title: "Les Points Relais Conseil VAE",
      description: "Pour vous aider dans vos démarches VAE, les Points Relais Conseil (PRC) vous proposent un entretien individuel pour discuter de votre projet.",
      body_class: 'home-white'
    )
  end

  def certificateur_vae_definition(conn, _params) do
    render(conn, "certificateur-vae-definition.html",
      title: "C'est quoi un certificateur VAE ?",
      description: "Tout comprendre sur le certificateur VAE, l'organisme qui vous délivrera votre diplôme. DAVA, CAVA, ASP n'auront plus de secret pour vous.",
      body_class: 'landing-extend'
    )
  end

  def pourquoi_une_certification(conn, _params) do
    render(conn, "pourquoi-une-certification.html",
      title: "Pourquoi un VAE ?",
      description: "Pas toujours évident de se lancer dans le processus de VAE. Explorez les bonnes raisons de se lancer dans l'obtention du diplôme.",
      body_class: 'landing-extend'
    )
  end

  def stats(conn, _params) do
    redirect(conn, external: "https://datastudio.google.com/u/0/reporting/1t7iUT7wGQn9U7ODZeDyXIvIRlK-BJAZs/page/1M")
  end
end

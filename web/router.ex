defmodule Vae.Router do
  use Vae.Web, :router
  use ExAdmin.Router
  use Coherence.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Coherence.Authentication.Session)
    plug(Vae.Tracker)
  end

  pipeline :protected do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Coherence.Authentication.Session, protected: true)
  end

  pipeline :api do
    plug(:accepts, ["json"])

    post("/mail_events", Vae.MailEventsController, :new_event)
  end

  scope "/" do
    pipe_through(:browser)
    coherence_routes()
  end

  scope "/" do
    pipe_through(:protected)
    coherence_routes(:protected)
  end

  scope "/", Vae do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index, as: :root)
    get("/vae", PageController, :vae)
    get("/conditions-generales-d-utilisation", PageController, :terms_of_use)
    get("/bien-choisir-son-diplome-vae", PageController, :choose_certification)
    get("/avril-aime-tous-ses-utilisateurs", PageController, :accessibility_promess)
    get("/point-relais-conseil-vae", PageController, :point_relais_conseil)
    get("/certificateur-vae-definition", PageController, :certificateur_vae_definition)
    get("/pourquoi-une-certification", PageController, :pourquoi_une_certification)

    get("/stats", PageController, :stats)

    get("/professions", ProfessionController, :index)

    get("/certifications", CertificationController, :index)
    get("/certifications/:id", CertificationController, :show)
    get("/certifications/:id/certifiers", CertificationController, :certifiers)

    resources("/certifiers", CertifierController, only: [:index, :show])
    get("/certifiers/:id/delegates", CertifierController, :delegates)

    resources("/delegates", DelegateController, only: [:index, :show])

    get("/processes", ProcessController, :index)
    get("/processes/:id", ProcessController, :show)
    get("/processes/:id/delegates", ProcessController, :delegates)
    post("/processes/contact", ProcessController, :contact)

    post("/search", SearchController, :search)
  end

  scope "/admin", ExAdmin do
    pipe_through(:protected)
    admin_routes()
  end
end

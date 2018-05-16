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
    plug(Vae.Wizard)
    plug(Coherence.Authentication.Session)
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

    get("/professions", ProfessionController, :index)
    get("/professions/_suggest", ProfessionController, :suggest)

    resources("/romes", RomeController, only: [:index, :show])
    get("/romes/:id/certifications", RomeController, :certifications)

    get("/certifications", CertificationController, :index)
    get("/certifications/:id", CertificationController, :show)
    get("/certifications/:id/certifiers", CertificationController, :certifiers)

    resources("/certifiers", CertifierController, only: [:index, :show])
    get("/certifiers/:id/delegates", CertifierController, :delegates)

    resources("/delegates", DelegateController, only: [:index, :show])

    get("/processes", ProcessController, :index)
    get("/processes/:id", ProcessController, :show)
    get("/processes/:id/delegates", ProcessController, :delegates)
    post("/processes", ProcessController, :search)
  end

  scope "/admin", ExAdmin do
    pipe_through(:protected)
    admin_routes()
  end
end

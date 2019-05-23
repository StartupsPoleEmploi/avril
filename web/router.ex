defmodule Vae.Router do
  use Vae.Web, :router
  use ExAdmin.Router
  use Coherence.Router

  # alias Redirector

  @user_schema Application.get_env(:coherence, :user_schema)
  @id_key Application.get_env(:coherence, :schema_key)

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)

    plug(Coherence.Authentication.Session,
      store: Coherence.CredentialStore.Session,
      db_model: @user_schema,
      id_key: @id_key
    )

    #    plug(Vae.Tracker)
  end

  pipeline :protected do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)

    plug(Coherence.Authentication.Session,
      protected: true,
      store: Coherence.CredentialStore.Session,
      db_model: @user_schema,
      id_key: @id_key
    )
  end

  pipeline :admin do
    plug(Vae.CheckAdmin)
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

    # Landing pages
    get("/", PageController, :index, as: :root)
    get("/vae", PageController, :vae)
    get("/conditions-generales-d-utilisation", PageController, :terms_of_use)
    get("/bien-choisir-son-diplome-vae", PageController, :choose_certification)
    get("/avril-aime-tous-ses-utilisateurs", PageController, :accessibility_promess)
    get("/point-relais-conseil-vae", PageController, :point_relais_conseil)
    get("/certificateur-vae-definition", PageController, :certificateur_vae_definition)
    get("/pourquoi-une-certification", PageController, :pourquoi_une_certification)
    get("/stats", PageController, :stats)

    get("/:provider/callback", AuthController, :callback)
    get("/:provider/redirect", AuthController, :save_session_and_redirect)

    # Basic navigation
    resources("/metiers", ProfessionController, only: [:index])
    resources("/certificateurs", DelegateController, only: [:index])
    resources("/diplomes", CertificationController, only: [:index, :show])

    # Loggued in applications
    get("/candidatures/:id/admissible", ApplicationController, :admissible)
    get("/candidatures/:id/inadmissible", ApplicationController, :inadmissible)

    get("/candidats/:id/admissible", JobSeekerController, :admissible)
    get("/candidats/:id/inadmissible", JobSeekerController, :inadmissible)

    resources("/candidatures", ApplicationController, only: [:show, :update]) do
      get("/telecharger", ApplicationController, :download, as: :download)
    end

    resources("/profil", UserController, only: [:update])

    # Search endpoint
    post("/search", SearchController, :search)

    # Old URL redirections
    get("/professions", Redirector, to: "/metiers")
    get("/delegates/:id", Redirector, to: "/diplomes?certificateur=:id")
    get("/certifications", Redirector, to: "/diplomes")
    get("/certifications/:id", Redirector, to: "/diplomes/:id")
    get("/certifiers/:id", Redirector, to: "/certificateurs?organisme=:id")
    get("/processes/:id", Redirector, [to: "/", msg: "La page demandée n'existe plus."])
  end

  scope "/admin", ExAdmin do
    pipe_through([:protected, :admin])
    admin_routes()
  end
end

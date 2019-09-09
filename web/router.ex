defmodule Vae.Router do
  use Vae.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug
  use ExAdmin.Router
  use Coherence.Router

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

    plug :put_user_token
    #    plug(Vae.Tracker)
  end

  pipeline :protected do
    # plug(:accepts, ["html"])
    # plug(:fetch_session)
    # plug(:fetch_flash)
    # plug(:protect_from_forgery)
    # plug(:put_secure_browser_headers)

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

  # Public Pages
  scope "/" do
    pipe_through(:browser)

    # Sessions routes
    coherence_routes()

    # Landing pages
    get("/", Vae.PageController, :index, as: :root)
    get("/vae", Vae.PageController, :vae)
    get("/conditions-generales-d-utilisation", Vae.PageController, :terms_of_use)
    get("/bien-choisir-son-diplome-vae", Vae.PageController, :choose_certification)
    get("/avril-aime-tous-ses-utilisateurs", Vae.PageController, :accessibility_promess)
    get("/point-relais-conseil-vae", Vae.PageController, :point_relais_conseil)
    get("/certificateur-vae-definition", Vae.PageController, :certificateur_vae_definition)
    get("/pourquoi-une-certification", Vae.PageController, :pourquoi_une_certification)
    get("/contact", Vae.PageController, :contact)
    post("/contact", Vae.PageController, :submit_contact)
    get("/financement-vae", Vae.PageController, :financement)
    get("/stats", Vae.PageController, :stats)

    # Basic navigation
    resources("/metiers", Vae.ProfessionController, only: [:index])
    resources("/certificateurs", Vae.DelegateController, only: [:index])
    resources("/diplomes", Vae.CertificationController, only: [:index, :show])

    # Search endpoint
    post("/search", Vae.SearchController, :search)

    # OAuth
    get("/:provider/callback", Vae.AuthController, :callback)
    get("/:provider/redirect", Vae.AuthController, :save_session_and_redirect)

    # Loggued in applications
    resources("/candidatures", Vae.ApplicationController, only: [:show, :update]) do
      get("/telecharger", Vae.ApplicationController, :download, as: :download)

      get("/france-vae-redirect", Vae.ApplicationController, :france_vae_redirect,
        as: :france_vae_redirect
      )

      get("/france-vae-registered", Vae.ApplicationController, :france_vae_registered,
        as: :france_vae_registered
      )

      resources("/resume", Vae.ResumeController, only: [:create, :delete])
    end

    get("/candidatures/:id/admissible", Vae.ApplicationController, :admissible)
    get("/candidatures/:id/inadmissible", Vae.ApplicationController, :inadmissible)

    # Mailing link redirection
    get("/candidats/:id/admissible", Vae.JobSeekerController, :admissible)
    get("/candidats/:id/inadmissible", Vae.JobSeekerController, :inadmissible)

    resources("/profil", Vae.UserController, only: [:update])

    # Old URL redirections
    get("/professions", Vae.Redirector, to: "/metiers")
    get("/delegates/:id", Vae.Redirector, to: "/diplomes?certificateur=:id")
    get("/certifications", Vae.Redirector, to: "/diplomes")
    get("/certifications/:id", Vae.Redirector, to: "/diplomes/:id")
    get("/certifiers/:id", Vae.Redirector, to: "/certificateurs?organisme=:id")
    get("/processes/:id", Vae.Redirector, to: "/", msg: "La page demandée n'existe plus.")
  end

  # Private pages
  scope "/" do
    pipe_through([:browser, :protected])
    coherence_routes(:protected)
  end

  # Admin
  scope "/admin", ExAdmin do
    pipe_through([:browser, :protected, :admin])
    get("/sql", ApiController, :sql)
    admin_routes()
  end

  defp put_user_token(conn, _) do
    if current_user = Coherence.current_user(conn) do
      assign(conn, :user_token, Phoenix.Token.sign(conn, "user socket", current_user.id))
    else
      conn
    end
  end
end

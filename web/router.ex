defmodule Vae.Router do
  use Vae.Web, :router
  use Plug.ErrorHandler
  use Sentry.Plug
  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    otp_app: :vae,
    extensions: [PowResetPassword, PowEmailConfirmation]

  use ExAdmin.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_app_status)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Pow.Plug.Session, otp_app: :vae)
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :api_protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Vae.APIAuthErrorHandler
  end

  pipeline :admin do
    plug(Vae.CheckAdmin)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(Vae.APIAuthPlug, otp_app: :vae)
    plug(:fetch_session)
    plug(:fetch_flash)

    post("/mail_events", Vae.MailEventsController, :new_event)
  end

  # Public Pages
  scope "/" do
    pipe_through(:browser)

    forward "/healthcheck", HealthCheckup

    # Landing pages
    get("/", Vae.PageController, :index, as: :root)
    get("/vae", Vae.PageController, :vae)
    get("/conditions-generales-d-utilisation", Vae.PageController, :terms_of_use)
    get("/justificatifs-vae", Vae.PageController, :receipts)
    get("/bien-choisir-son-diplome-vae", Vae.PageController, :choose_certification)
    get("/avril-aime-tous-ses-utilisateurs", Vae.PageController, :accessibility_promess)
    get("/point-relais-conseil-vae", Vae.PageController, :point_relais_conseil)
    get("/certificateur-vae-definition", Vae.PageController, :certificateur_vae_definition)
    get("/pourquoi-une-certification", Vae.PageController, :pourquoi_une_certification)
    get("/contact", Vae.PageController, :contact)
    post("/contact", Vae.PageController, :submit_contact)
    get("/financement-vae", Vae.PageController, :financement)
    post("/close-app-status", Vae.PageController, :close_status)
    get("/stats", Vae.PageController, :stats)

    pow_routes()
    pow_extension_routes()

    # Basic navigation
    resources("/rome", Vae.RomeController, only: [:index, :show])
    # resources("/metiers", Vae.ProfessionController, only: [:show])
    resources("/certificateurs", Vae.DelegateController, only: [:index, :show])

    resources("/diplomes", Vae.CertificationController, only: [:index, :show]) do
      put("/select", Vae.CertificationController, :select, as: :select)
    end

    # Search endpoint
    post("/search", Vae.SearchController, :search)

    # OAuth
    get("/:provider/callback", Vae.AuthController, :callback)
    get("/:provider/redirect", Vae.AuthController, :save_session_and_redirect)

    # Loggued in applications
    resources("/candidatures", Vae.ApplicationController, only: [:index, :show, :update]) do
      get("/telecharger", Vae.ApplicationController, :download, as: :download)

      get("/france-vae-redirect", Vae.ApplicationController, :france_vae_redirect,
        as: :france_vae_redirect
      )

      get("/france-vae-registered", Vae.ApplicationController, :france_vae_registered,
        as: :france_vae_registered
      )

      resources("/resume", Vae.ApplicationController.ResumeController, only: [:create, :delete])
    end

    get("/candidatures/:id/admissible", Vae.ApplicationController, :admissible)
    get("/candidatures/:id/inadmissible", Vae.ApplicationController, :inadmissible)

    # Mailing link redirection
    resources("/candidats", Vae.JobSeekerController, only: [:create])
    get("/candidats/:id/admissible", Vae.JobSeekerController, :admissible)
    get("/candidats/:id/inadmissible", Vae.JobSeekerController, :inadmissible)

    resources("/profil", Vae.UserController, only: [:update]) do
      post("/resend_confirmation_email", Vae.UserController, :resend_confirmation_email)
    end

    # Old URL redirections
    get("/professions", Vae.Redirector, to: "/metiers")
    get("/delegates/:id", Vae.Redirector, to: "/diplomes?certificateur=:id")
    get("/certifications", Vae.Redirector, to: "/diplomes")
    get("/certifications/:id", Vae.Redirector, to: "/diplomes/:id")
    get("/certifiers/:id", Vae.Redirector, to: "/certificateurs?organisme=:id")
    get("/processes/:id", Vae.Redirector, to: "/", msg: "La page demandée n'existe plus.")
  end

  scope "/api" do
    pipe_through([:api])
    get("/booklet", Vae.ApiController, :get_booklet)
    put("/booklet", Vae.ApiController, :set_booklet)
  end

  scope "/api/v1", as: :api_v1 do
    pipe_through([:api])

    resources("/session", Vae.Api.SessionController, singleton: true, only: [:create, :delete])
  end

  scope "/api/v1", as: :api_v1 do
    pipe_through([:api, :api_protected])
    # get("/booklet", Vae.Api.BookletController, :get_booklet)
    # put("/booklet", Vae.Api.BookletController, :set_booklet)
    get("/profile", Vae.Api.ProfileController, :index)
    put("/profile", Vae.Api.ProfileController, :update)

    get("/applications", Vae.Api.ApplicationController, :list)
    get("/applications/:id", Vae.Api.ApplicationController, :dashboard)
    get("/applications/:id/delegates", Vae.Api.ApplicationController, :delegates_search)

    post("/delegates/search", Vae.Api.DelegateController, :search)

    post("/meetings/search", Vae.Api.MeetingController, :search)
  end

  # Admin
  scope "/admin", ExAdmin do
    pipe_through([:browser, :protected, :admin])
    get("/sql", ApiController, :sql)
    get("/status", ApiController, :get_status)
    post("/status", ApiController, :put_status)
    delete("/status", ApiController, :delete_status)
    admin_routes()
  end

  defp fetch_app_status(conn, _opts) do
    status = GenServer.call(Status, :get)
    # There is a status
    # not closed
    # in interval
    if status &&
         get_session(conn, :app_status_closed) != Vae.String.encode(status.message) &&
         (is_nil(status.starts_at) || Timex.before?(status.starts_at, Timex.now())) &&
         (is_nil(status.ends_at) || Timex.after?(status.ends_at, Timex.now())) do
      Map.merge(conn, %{app_status: status})
    else
      conn
    end
  end
end

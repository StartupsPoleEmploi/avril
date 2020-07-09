defmodule VaeWeb.Router do
  use VaeWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug
  use ExAdmin.Router
  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    otp_app: :vae,
    extensions: [
      # PowEmailConfirmation,
      PowResetPassword
    ]

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_app_status)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :not_authenticated do
    plug Pow.Plug.RequireNotAuthenticated,
      error_handler: VaeWeb.Plugs.ErrorHandlers.Browser
  end

  pipeline :protected do
    plug(Pow.Plug.RequireAuthenticated,
      error_handler: VaeWeb.Plugs.ErrorHandlers.Browser
    )
  end

  pipeline :admin do
    plug(VaeWeb.Plugs.CheckAdmin)
  end

  pipeline :accepts_json do
    plug(:accepts, ["json"])
  end

  pipeline :api_protected_login_only do
    plug(VaeWeb.Plugs.ApiProtected)
  end

  pipeline :api_protected_login_or_server do
    plug(VaeWeb.Plugs.ApiProtected, allow_server_side: true)
  end

  pipeline :maybe_set_current_application do
    plug(
      VaeWeb.Plugs.ApplicationAccess,
      find_with_hash: true,
      optional: true,
      error_handler: VaeWeb.Plugs.ErrorHandlers.API
    )
  end

  pipeline :set_current_application do
    plug(
      VaeWeb.Plugs.ApplicationAccess,
      find_with_hash: true,
      error_handler: VaeWeb.Plugs.ErrorHandlers.API
    )
  end

  pipeline :set_graphql_context do
    plug(VaeWeb.Plugs.AddGraphqlContext)
  end

  # Public Pages
  scope "/" do
    pipe_through(:browser)

    forward "/healthcheck", HealthCheckup

    # Landing pages
    get("/", VaeWeb.PageController, :index, as: :root)
    get("/vae", VaeWeb.PageController, :vae)
    get("/conditions-generales-d-utilisation", VaeWeb.PageController, :terms_of_use)
    get("/justificatifs-vae", VaeWeb.PageController, :receipts)
    get("/synthese-vae", VaeWeb.PageController, :synthesis)
    get("/bien-choisir-son-diplome-vae", VaeWeb.PageController, :choose_certification)
    get("/avril-aime-tous-ses-utilisateurs", VaeWeb.PageController, :accessibility_promess)
    get("/point-relais-conseil-vae", VaeWeb.PageController, :point_relais_conseil)
    get("/certificateur-vae-definition", VaeWeb.PageController, :certificateur_vae_definition)
    get("/pourquoi-une-certification", VaeWeb.PageController, :pourquoi_une_certification)
    get("/contact", VaeWeb.PageController, :contact)
    post("/contact", VaeWeb.PageController, :submit_contact)
    get("/financement-vae", VaeWeb.PageController, :financement)
    get("/tester-mon-eligibilite-vae", VaeWeb.UserController, :eligibility)
    post("/close-app-status", VaeWeb.PageController, :close_status)
    get("/stats", VaeWeb.PageController, :stats)

    # Basic navigation
    resources("/rome", VaeWeb.RomeController, only: [:index, :show])
    get("/certificateurs", VaeWeb.DelegateController, :geo)
    get("/certificateurs/:administrative", VaeWeb.DelegateController, :geo)

    resources("/certificateurs/:administrative/:city", VaeWeb.DelegateController,
      only: [:index, :show, :update]
    )

    resources("/diplomes", VaeWeb.CertificationController, only: [:index, :show]) do
      put("/select", VaeWeb.CertificationController, :select, as: :select)
    end

    # Search endpoint
    post("/search", VaeWeb.SearchController, :search)

    # OAuth
    get("/:provider/callback", VaeWeb.AuthController, :callback)
    get("/:provider/redirect", VaeWeb.AuthController, :save_session_and_redirect)

    # Loggued in applications
    resources("/candidatures", VaeWeb.UserApplicationController, only: [:index, :show])

    get("/candidatures/:id/admissible", VaeWeb.UserApplicationController, :admissible)
    get("/candidatures/:id/inadmissible", VaeWeb.UserApplicationController, :inadmissible)
    get("/candidatures/:id/cerfa", VaeWeb.UserApplicationController, :cerfa)

    # Mailing link redirection
    resources("/candidats", VaeWeb.JobSeekerController, only: [:create])
    get("/candidats/:id/admissible", VaeWeb.JobSeekerController, :admissible)
    get("/candidats/:id/inadmissible", VaeWeb.JobSeekerController, :inadmissible)

    # Old URL redirections
    get("/professions", VaeWeb.Redirector, to: "/metiers")
    get("/delegates/:id", VaeWeb.Redirector, to: "/diplomes?certificateur=:id")
    get("/certifications", VaeWeb.Redirector, to: "/diplomes")
    get("/certifications/:id", VaeWeb.Redirector, to: "/diplomes/:id")
    get("/certifiers/:id", VaeWeb.Redirector, to: "/certificateurs?organisme=:id")
    get("/processes/:id", VaeWeb.Redirector, to: "/", msg: "La page demandée n'existe plus.")
  end

  scope "/", VaeWeb do
    pipe_through [:browser, :not_authenticated]

    get("/signup", RegistrationController, :new, as: :signup)
    post("/signup", RegistrationController, :create, as: :signup)
    get("/login", SessionController, :new, as: :login)
    post("/login", SessionController, :create, as: :login)

    resources("/reset-password", ResetPasswordController,
      as: :reset_password,
      only: [:new, :create, :edit, :update]
    )
  end

  scope "/", VaeWeb do
    pipe_through [:browser, :protected]

    delete("/logout", SessionController, :delete, as: :logout)
    # For nuxt_profile
    get("/disconnect", SessionController, :delete)
  end

  # Admin
  scope "/admin", ExAdmin do
    pipe_through([:browser, :protected, :admin])
    get("/sql", ApiController, :sql)
    get("/status", ApiController, :get_status)
    post("/status", ApiController, :put_status)
    delete("/status", ApiController, :delete_status)
    put("/set-current-user/:id", ApiController, :set_current_user)
    admin_routes()
  end

  scope "/" do
    pipe_through [:accepts_json]
    post("/mail_events", VaeWeb.MailEventsController, :new_event)
  end

  scope "/api" do
    pipe_through [
      :accepts_json,
      :api_protected_login_or_server,
      :maybe_set_current_application,
      :set_graphql_context
    ]

    forward "/v2", Absinthe.Plug,
      schema: VaeWeb.Schema,
      before_send: {__MODULE__, :logout?},
      json_codec: Jason

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: VaeWeb.Schema,
      before_send: {__MODULE__, :logout?},
      interface: :playground,
      json_codec: Jason
  end

  # deprecated: should be moved to Absinthe
  scope "/api" do
    pipe_through([
      :accepts_json,
      # :api_protected_login_or_server,
      :set_current_application
    ])

    get("/booklet", VaeWeb.ApiController, :get_booklet)
    put("/booklet", VaeWeb.ApiController, :set_booklet)
  end

  def logout?(conn, %Absinthe.Blueprint{} = blueprint) do
    if blueprint.execution.context[:current_user] do
      conn
    else
      conn
      |> Plug.Conn.assign(:signed_out_user, Pow.Plug.current_user(conn))
      |> Pow.Plug.delete()
    end
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

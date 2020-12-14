defmodule VaeWeb.Router do
  use VaeWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug
  use ExAdmin.Router
  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    otp_app: :vae,
    extensions: [PowResetPassword]

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

  pipeline :authenticated do
    plug(Pow.Plug.RequireAuthenticated,
      error_handler: VaeWeb.Plugs.ErrorHandlers.Browser
    )
  end

  pipeline :admin do
    plug(VaeWeb.Plugs.CheckAdmin)
    plug(VaeWeb.Plugs.RemoveOverrideUser)
  end

  pipeline :accepts_json do
    plug(:accepts, ["json"])
  end

  pipeline :api_authenticated do
    plug(Pow.Plug.RequireAuthenticated,
      error_handler: VaeWeb.Plugs.ErrorHandlers.API
    )
    plug(VaeWeb.Plugs.AddGraphqlContext)
  end

  # Public Pages
  scope "/" do
    pipe_through(:browser)

    forward "/healthcheck", HealthCheckup

    # Landing pages
    get("/", VaeWeb.PageController, :index, as: :root)
    get("/vae", VaeWeb.PageController, :vae)
    get("/faq", VaeWeb.PageController, :faq)
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

    # Public navigation
    resources("/rome", VaeWeb.RomeController, only: [:index, :show])
    get("/certificateurs", VaeWeb.DelegateController, :geo)
    get("/certificateurs/:administrative", VaeWeb.DelegateController, :geo)
    resources("/certificateurs/:administrative/:city", VaeWeb.DelegateController,
      only: [:index, :show, :update]
    )

    resources("/diplomes", VaeWeb.CertificationController, only: [:index, :show]) do
      put("/select", VaeWeb.CertificationController, :select, as: :select)
    end

    # OAuth
    get("/:provider/callback", VaeWeb.AuthController, :callback)
    get("/:provider/redirect", VaeWeb.AuthController, :save_session_and_redirect)

    # Delegate applications views
    resources("/candidatures", VaeWeb.UserApplicationController, only: [:show])
    get("/candidatures/:id/cerfa", VaeWeb.UserApplicationController, :cerfa)

    # Mailing link redirection
    get("/candidatures/:id/admissible", VaeWeb.UserApplicationController, :admissible)
    get("/candidatures/:id/inadmissible", VaeWeb.UserApplicationController, :inadmissible)

    # Still used?
    get("/candidats/:id/admissible", VaeWeb.JobSeekerController, :admissible)
    get("/candidats/:id/inadmissible", VaeWeb.JobSeekerController, :inadmissible)

    # Old URL redirections
    get("/professions", VaeWeb.Redirector, to: "/metiers")
    get("/delegates/:id", VaeWeb.Redirector, to: "/diplomes?certificateur=:id")
    get("/certifications", VaeWeb.Redirector, to: "/diplomes")
    get("/certifications/:id", VaeWeb.Redirector, to: "/diplomes/:id")
    get("/certifiers/:id", VaeWeb.Redirector, to: "/certificateurs?organisme=:id")
    get("/processes/:id", VaeWeb.Redirector, to: "/", msg: "La page demandée n'existe plus.")

    post("/search", VaeWeb.SearchController, :search)
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
    pipe_through [:browser, :authenticated]

    delete("/logout", SessionController, :delete, as: :logout)
    # For nuxt_profile
    get("/disconnect", SessionController, :delete)
  end

  # Admin
  scope "/admin", ExAdmin do
    pipe_through([:browser, :authenticated, :admin])
    get("/sql", ApiController, :sql)
    get("/status", ApiController, :get_status)
    post("/status", ApiController, :put_status)
    delete("/status", ApiController, :delete_status)
    admin_routes()
  end

  # API
  scope "/" do
    pipe_through [:accepts_json]
    post("/mail_events", VaeWeb.MailEventsController, :new_event)

    get("/search", VaeWeb.SearchController, :public_search)

    # API
    forward "/api/v2", Absinthe.Plug,
      schema: VaeWeb.Schema,
      before_send: {__MODULE__, :logout?},
      json_codec: Jason

    if Mix.env() == :dev do
      forward "/api/graphiql", Absinthe.Plug.GraphiQL,
        schema: VaeWeb.Schema,
        before_send: {__MODULE__, :logout?},
        interface: :playground,
        json_codec: Jason
    end
  end

  # # Private API
  # scope "/api" do
  #   pipe_through [
  #     :accepts_json,
  #     :api_authenticated
  #   ]

  #   forward "/v2", Absinthe.Plug,
  #     schema: VaeWeb.Schema.Private,
  #     before_send: {__MODULE__, :logout?},
  #     json_codec: Jason

  # end

  def logout?(conn, %Absinthe.Blueprint{} = blueprint) do
    conn
    # IO.inspect(Absinthe.Blueprint.current_operation(blueprint))
    # if blueprint.execution.context[:current_user] do
    #   conn
    # else
    #   conn
    #   |> Plug.Conn.assign(:signed_out_user, Pow.Plug.current_user(conn))
    #   |> Pow.Plug.delete()
    # end
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
      Plug.Conn.assign(conn, :app_status, status)
    else
      conn
    end
  end
end

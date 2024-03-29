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

  pipeline :is_delegate do
    plug(VaeWeb.Plugs.CheckIsDelegate)
  end

  pipeline :is_admin do
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
    get("/politique-de-confidentialite", VaeWeb.PageController, :privacy_policy)
    get("/justificatifs-vae", VaeWeb.PageController, :receipts)
    get("/synthese-vae", VaeWeb.PageController, :synthesis)
    get("/bien-choisir-son-diplome-vae", VaeWeb.PageController, :choose_certification)
    get("/avril-aime-tous-ses-utilisateurs", VaeWeb.PageController, :accessibility_promess)
    get("/certificateur-vae-definition", VaeWeb.PageController, :certificateur_vae_definition)
    get("/pourquoi-une-certification", VaeWeb.PageController, :pourquoi_une_certification)
    get("/contact", VaeWeb.PageController, :contact)
    post("/contact", VaeWeb.PageController, :submit_contact)
    get("/delegate_contact", VaeWeb.PageController, :delegate_contact)
    post("/delegate_contact", VaeWeb.PageController, :submit_delegate_contact)
    get("/financement-vae", VaeWeb.PageController, :financement)
    get("/tester-mon-eligibilite-vae", VaeWeb.UserController, :eligibility)
    post("/close-app-status", VaeWeb.PageController, :close_status)
    get("/stats", VaeWeb.PageController, :stats)
    get("/sql", VaeWeb.StatsController, :sql)

    # Public navigation
    resources("/rome", VaeWeb.RomeController, only: [:index, :show])
    get("/certificateurs", VaeWeb.DelegateController, :geo)
    get("/certificateurs/:administrative", VaeWeb.DelegateController, :geo)
    resources("/certificateurs/:administrative/:city", VaeWeb.DelegateController,
      only: [:index, :show, :update]
    )
    get("/point-relais-conseil-vae", VaeWeb.DelegateController, :geo, as: :prc)
    resources("/point-relais-conseil-vae/:administrative", VaeWeb.DelegateController,
      only: [:index], as: :prc
    )
    get("/activate_delegate_access", VaeWeb.DelegateAuthenticatedController, :activate)

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


  scope "/mon-espace-certificateur", VaeWeb do
    pipe_through [:browser, :authenticated, :is_delegate]
    resources("/", DelegateAuthenticatedController, only: [:index, :show, :edit, :update]) do
      get("/candidatures", DelegateAuthenticatedController, :applications, as: :applications)
      get("/diplomes", DelegateAuthenticatedController, :certifications, as: :certifications)

    end
  end

  # Admin
  scope "/admin", ExAdmin do
    pipe_through([:browser, :authenticated, :is_admin])
    get("/sql", ApiController, :sql)
    get("/status", ApiController, :get_status)
    post("/status", ApiController, :put_status)
    delete("/status", ApiController, :delete_status)
    admin_routes()
  end

  # API
  scope "/" do
    pipe_through [:accepts_json]
    get("/search", VaeWeb.SearchController, :public_search)

    # API
    # forward "/api/v2", Absinthe.Plug,
    #   schema: VaeWeb.Schema,
    #   before_send: {__MODULE__, :logout?},
    #   json_codec: Jason

  end

  # # Private API
  scope "/api" do
    pipe_through [
      :accepts_json,
      :api_authenticated
    ]

    forward "/v2", Absinthe.Plug,
      schema: VaeWeb.Schema,
      before_send: {__MODULE__, :logout?},
      json_codec: Jason

    if Mix.env() != :prod do
      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: VaeWeb.Schema,
        before_send: {__MODULE__, :logout?},
        interface: :playground,
        json_codec: Jason
    end
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
    closed_statuses = (get_session(conn, :app_status_closed) || "") |> String.split(",", trim: true)

    displayed_statuses = GenServer.call(Status, :get)
    |> Enum.reject(fn status ->
      is_nil(status) ||
      Enum.member?(closed_statuses, status.id) ||
      (status.starts_at && Timex.before?(Timex.now(), status.starts_at)) ||
      (status.ends_at && Timex.after?(Timex.now(), status.ends_at))
    end)
    if length(displayed_statuses) do
      Plug.Conn.assign(conn, :app_status, displayed_statuses)
    else
      conn
    end
  end
end

# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :vae,
  ecto_repos: [Vae.Repo],
  places_client: Vae.Places.Client.Algolia,
  search_client: Vae.Search.Client.Algolia,
  meetings_indice: System.get_env("ALGOLIA_MEETINGS_INDICE"),
  places_ets_table_name: :places_dev,
  algolia_places_app_id: System.get_env("ALGOLIA_PLACES_APP_ID"),
  algolia_places_api_key: System.get_env("ALGOLIA_PLACES_API_KEY"),
  authentication: [
    client_id: System.get_env("PE_CONNECT_CLIENT_ID"),
    client_secret: System.get_env("PE_CONNECT_CLIENT_SECRET"),
    site: "https://authentification-candidat.pole-emploi.fr",
    authorize_url: "/connexion/oauth2/authorize",
    redirect_uri:
      "#{if Mix.env() == :dev, do: "http", else: "https"}://#{
        System.get_env("WHOST") || "localhost"
      }/pole-emploi/callback"
  ],
  tracking: [
    analytics: System.get_env("GA_API_KEY"),
    analytics_bis: System.get_env("GA_PE_API_KEY"),
    crisp: System.get_env("CRISP_WEBSITE_ID"),
    hotjar: System.get_env("HOTJAR_ID"),
    optimize: System.get_env("GO_TEST_KEY")
  ],
  reminders: [
    stock: [
      users: [
        template_id: 848_006,
        form_urls: [
          certifiers: [
            default: %{
              url: System.get_env("TYPEFORM_STOCK_REMINDER")
            }
          ]
        ]
      ]
    ],
    monthly: [
      users: [
        template_id: 768_365,
        form_urls: [
          certifiers: [
            asp: %{
              ids: [1, 3],
              url: System.get_env("TYPEFORM_MONTH_BACK_ASP")
            },
            educ_nat: %{
              ids: [2],
              url: System.get_env("TYPEFORM_MONTH_BACK_EDUC_NAT")
            },
            labour_ministry: %{
              ids: [4],
              url: System.get_env("TYPEFORM_MONTH_BACK_MINISTRY")
            },
            other: %{
              ids: [],
              url: System.get_env("TYPEFORM_MONTH_BACK_OTHER")
            }
          ]
        ]
      ]
    ]
  ]

config :vae, Vae.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: Vae.ErrorView, accepts: ~w(html email json)],
  pubsub: [name: Vae.PubSub, adapter: Phoenix.PubSub.PG2]

config :vae, Vae.Repo,
  adapter: Ecto.Adapters.Postgres,
  url:
    System.get_env("DATABASE_URL") ||
      "postgres://#{System.get_env("POSTGRES_USER")}:#{System.get_env("POSTGRES_PASSWORD")}@#{
        System.get_env("POSTGRES_HOST")
      }/#{System.get_env("POSTGRES_DB")}",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: false,
  timeout: 60_000

config :vae, Vae.Mailer,
  adapter: Swoosh.Adapters.Mailjet,
  api_key: System.get_env("MAILJET_PUBLIC_API_KEY"),
  secret: System.get_env("MAILJET_PRIVATE_API_KEY"),
  template_error_deliver: true,
  template_error_to: System.get_env("DEV_EMAILS") || "avril@pole-emploi.fr",
  avril_name: "Avril - la VAE facile - service numérique de Pôle emploi",
  avril_from: "contact@avril.pole-emploi.fr",
  avril_to: "avril@pole-emploi.fr",
  override_to: System.get_env("DEV_EMAILS")

config :vae, :pow,
  repo: Vae.Repo,
  user: Vae.User,
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  extensions: [PowEmailConfirmation, PowResetPassword],
  mailer_backend: Vae.PowMailer,
  messages_backend: Vae.Pow.Messages,
  web_module: Vae

config :algolia,
  application_id: System.get_env("ALGOLIA_APP_ID"),
  api_key: System.get_env("ALGOLIA_API_KEY"),
  search_api_key: System.get_env("ALGOLIA_SEARCH_API_KEY")

# config :coherence,
#   allow_unconfirmed_access_for: 365,
#   email_from_email: "contact@avril.pole-emploi.fr",
#   email_from_name: "Avril",
#   # default_routes: %{
#   #   registrations_new:  "/souscription/nouvelle",
#   #   registrations:      "/souscription",
#   #   passwords:          "/mot-de-passe",
#   #   confirmations:      "/confirmations",
#   #   unlocks:            "/debloquage",
#   #   invitations:        "/invitations",
#   #   invitations_create: "/invitations/create",
#   #   invitations_resend: "/invitations/:id/renvoyer",
#   #   sessions:           "/connexions",
#   #   registrations_edit: "/souscription/edition"
#   #   },
#   messages_backend: Vae.Coherence.Messages,
#   opts: [
#     :authenticatable,
#     :confirmable,
#     :registerable,
#     :recoverable,
#     # :rememberable,
#     :lockable,
#     :trackable,
#     :unlockable_with_token,
#   ],
#   repo: Vae.Repo,
#   router: Vae.Router,
#   session_model: Vae.Session,
#   session_repo: Vae.Repo,
#   schema_key: :id,
#   user_schema: Vae.User,
#   web_module: Vae

# config :coherence, :layout, {Vae.LayoutView, :coherence}

# config :coherence, :mailer, Vae.Mailer

# config :coherence, Vae.Coherence.Mailer,
#   adapter: Swoosh.Adapters.Mailjet,
#   api_key: System.get_env("MAILJET_PUBLIC_API_KEY"),
#   secret: System.get_env("MAILJET_PRIVATE_API_KEY")

config :cors_plug,
  origin: [System.get_env("NUXT_URL")],
  max_age: 86400,
  methods: ["GET", "POST", "PUT"],
  headers: ["*"]

config :ex_admin,
  head_template: {Vae.AdminView, "admin_layout.html"},
  repo: Vae.Repo,
  module: Vae,
  modules: [
    Vae.ExAdmin.Application,
    Vae.ExAdmin.AppStatus,
    Vae.ExAdmin.Dashboard,
    Vae.ExAdmin.Certification,
    Vae.ExAdmin.Certifier,
    Vae.ExAdmin.Delegate,
    Vae.ExAdmin.Process,
    Vae.ExAdmin.Profession,
    Vae.ExAdmin.Resume,
    Vae.ExAdmin.Rome,
    Vae.ExAdmin.User
  ]

config :ex_aws,
  access_key_id: [System.get_env("AWS_ACCESS_KEY_ID"), :instance_role],
  secret_access_key: [System.get_env("AWS_SECRET_ACCESS_KEY"), :instance_role],
  bucket_name: System.get_env("AWS_S3_BUCKET_NAME"),
  region: "eu-west-3",
  s3: [
    scheme: "https://",
    host: "#{System.get_env("AWS_S3_BUCKET_NAME")}.s3.amazonaws.com",
    region: "eu-west-3"
  ]

config :gettext, :default_locale, "fr"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine,
  # If you want to use LiveView
  slimleex: PhoenixSlime.LiveViewEngine,
  md: PhoenixMarkdown.Engine

config :phoenix_markdown, :earmark, %{
  gfm: true,
  breaks: true,
  pure_links: true
}

config :phoenix_markdown, :server_tags, :all

config :scrivener_html,
  routes_helper: Vae.Router.Helpers,
  view_style: :bootstrap_v4

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  release: System.get_env("FLYNN_RELEASE_ID"),
  included_environments: [:prod],
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

config :xain, :after_callback, {Phoenix.HTML, :raw}

import_config "#{Mix.env()}.exs"

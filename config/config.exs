# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# HTTP_SCHEME = if Mix.env() == :dev, do: "http", else: "https"
# WHOST = System.get_env("WHOST") || "localhost:4000"
# AVRIL_EMAIL = System.get_env("AVRIL_EMAIL") || "avril@pole-emploi.fr"
# ERROR_EMAILS = System.get_env("DEV_EMAILS") || AVRIL_EMAIL

# General application configuration
config :vae,
  ecto_repos: [Vae.Repo],
  places_client: Vae.Places.Client.Algolia,
  search_client: Vae.Search.Client.Algolia,
  places_ets_table_name: :places_dev,
  algolia_places_app_id: System.get_env("ALGOLIA_PLACES_APP_ID"),
  algolia_places_api_key: System.get_env("ALGOLIA_PLACES_API_KEY"),
  extractor: Vae.Mailer.FileExtractor.CsvExtractor,
  mailer_extractor_limit: 10_000,
  sender: Vae.Mailer.Sender.Mailjet,
  mailjet_template_error_reporting: %{Email: System.get_env("DEV_EMAILS") || "avril@pole-emploi.fr" |> String.split(",") |> List.first()},
  mailjet_template_error_deliver: true,
  mailjet: [
    application_submitted_to_delegate_id: 758_379,
    application_submitted_to_user_id: 764_589,
    campaign_template_id: 512_948,
    vae_recap_template_id: 529_420,
    dava_vae_recap_template_id: 878_833,
    asp_vae_recap_template_id: 833_668,
    contact_template_id: 543_455,
    from_email: "avril@pole-emploi.fr",
    from_name: "Avril"
  ],
  authentication: [
    client_id: System.get_env("PE_CONNECT_CLIENT_ID"),
    client_secret: System.get_env("PE_CONNECT_CLIENT_SECRET"),
    site: "https://authentification-candidat.pole-emploi.fr",
    authorize_url: "/connexion/oauth2/authorize",
    redirect_uri: "#{if Mix.env() == :dev, do: "http", else: "https"}://#{System.get_env("WHOST") || "localhost:4000"}/pole-emploi/callback"
  ],
  # Unused?
  statistics: %{
    email_from: System.get_env("DEV_EMAILS") || "avril@pole-emploi.fr" |> String.split(",") |> List.first(),
    email_from_name: "Avril",
    email_to: System.get_env("DEV_EMAILS") || "avril@pole-emploi.fr" |> String.split(",") |> List.first(),
    email_to_name: "Statisticien"
  }

config :vae, Vae.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: Vae.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Vae.PubSub, adapter: Phoenix.PubSub.PG2]

config :vae, Vae.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "postgres://#{System.get_env("POSTGRES_USER")}:#{System.get_env("POSTGRES_PASSWORD")}@#{System.get_env("POSTGRES_HOST")}/#{System.get_env("POSTGRES_DB")}",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: Mix.env() != :dev,
  timeout: 60_000

config :algolia,
  application_id: System.get_env("ALGOLIA_APP_ID"),
  api_key: System.get_env("ALGOLIA_API_KEY"),
  search_api_key: System.get_env("ALGOLIA_SEARCH_API_KEY")

config :coherence,
  web_module: Vae,
  user_schema: Vae.User,
  repo: Vae.Repo,
  router: Vae.Router,
  messages_backend: Vae.Coherence.Messages,
  email_from_name: "Avril",
  email_from_email: "avril@pole-emploi.fr",
  opts: [:authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token],
  session_model: Vae.Session,
  session_repo: Vae.Repo,
  schema_key: :id

config :coherence, :layout, {Vae.LayoutView, :app}

config :coherence, Vae.Coherence.Mailer,
  adapter: Swoosh.Adapters.Mailjet,
  api_key: System.get_env("MAILJET_PUBLIC_API_KEY"),
  secret: System.get_env("MAILJET_PRIVATE_API_KEY")

config :ex_admin,
  head_template: {Vae.AdminView, "admin_layout.html"},
  repo: Vae.Repo,
  module: Vae,
  modules: [
    Vae.ExAdmin.Application,
    Vae.ExAdmin.Dashboard,
    Vae.ExAdmin.Certification,
    Vae.ExAdmin.Certifier,
    Vae.ExAdmin.Delegate,
    Vae.ExAdmin.Process,
    Vae.ExAdmin.Profession,
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

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mailjex,
  api_base: "https://api.mailjet.com/v3.1",
  public_api_key: System.get_env("MAILJET_PUBLIC_API_KEY"),
  private_api_key: System.get_env("MAILJET_PRIVATE_API_KEY"),
  development_mode: false

config :phoenix, :json_library, Jason

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine,
  slimleex: PhoenixSlime.LiveViewEngine # If you want to use LiveView

config :scrivener_html,
  routes_helper: Vae.Router.Helpers,
  view_style: :bootstrap_v4

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  release: System.get_env("FLYNN_RELEASE_ID"),
  included_environments: [:prod],
  environment_name: Mix.env,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!

config :xain, :after_callback, {Phoenix.HTML, :raw}

import_config "#{Mix.env()}.exs"

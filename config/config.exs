# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :vae,
  ecto_repos: [Vae.Repo],
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
    optimize: System.get_env("GO_TEST_KEY"),
    tag_commander: System.get_env("TAG_COMMANDER")
  ],
  rncp: [
    url: "https://api.francecompetences.fr/referentiels/v1/fiches",
    api_key: System.get_env("RNCP_API_KEY")
  ],
  deadlines: [
    reva_end: ~D[2023-06-12],
    fvae_start: ~D[2023-07-04],
    avril_pre_close: ~D[2023-12-31],
    avril_close: ~D[2024-01-31],
  ],
  messages: [
    registration_closed: "Les inscriptions sont fermées sur Avril. Vous pouvez encore consulter votre espace personnel jusqu'au 31 Janvier 2024.\n\nPour un nouveau projet de diplôme en VAE, rendez-vous sur [France VAE](https://vae.gouv.fr).",
    support_closed: "Le support n'est malheureusement plus disponible pour répondre à vos questions.\n\nRendez-vous sur [France VAE](https://vae.gouv.fr)."
  ]

config :vae, VaeWeb.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: VaeWeb.ErrorView, accepts: ~w(html email json)],
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
  types: Vae.PostgresTypes,
  timeout: String.to_integer(System.get_env("POSTGRES_TIMEOUT") || "60000")


config :vae, VaeWeb.Mailer,
  adapter: Swoosh.Adapters.Mailjet,
  api_key: System.get_env("MAILJET_PUBLIC_API_KEY"),
  secret: System.get_env("MAILJET_PRIVATE_API_KEY"),
  template_error_deliver: true,
  template_error_to: System.get_env("DEV_EMAILS") || "avril@pole-emploi.fr",
  avril_name: "Avril - la VAE facile - service numérique de Pôle emploi",
  avril_from: "contact@avril.pole-emploi.fr",
  avril_to: "avril@fabrique.social.gouv.fr"

config :vae, :pow,
  repo: Vae.Repo,
  user: Vae.User,
  cache_store_backend: Pow.Store.Backend.MnesiaCache,
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  extensions: [
    PowResetPassword,
    PowPersistentSession
  ],
  password_min_length: 8,
  web_module: VaeWeb

config :vae, Vae.Scheduler,
  jobs: if Mix.env() == :prod, do: [
    raise_unsubmitted_applications: [
      schedule: "0 5 * * *", # 5AM every day
      task: {Vae.UserApplications.FollowUp, :send_unsubmitted_raise_email, []}
    ],
    # get_admissibility_updates: [
    #   schedule: "30 5 * * *", # 5.30AM every day
    #   task: {Vae.UserApplications.FollowUp, :send_admissibility_update_email, []}
    # ],
    send_delegate_recap: [
      schedule: "45 5 1,15 * *", # 5.45AM first and 15th of month
      task: {Vae.UserApplications.FollowUp, :send_delegate_recap_email, []}
    ],
    meetings_task: [
      schedule: "0 5,13 * * *", # 5AM & 1PM every day
      task: &Vae.Meetings.fetch_meetings/0
    ],
    update_materialized_views: [
      schedule: "0 6 * * *", # 6AM every day
      task: fn ->
        Vae.Search.FullTextSearch.refresh_materialized_view()
        Vae.Certification.refresh_materialized_view()
      end
    ],
    anonymization_task: [
      schedule: "0 2 1 * *", # 2AM on the first of month
      task: &Vae.Rgpd.Anonymize.anonymize_all/0
    ],
    rncp_update_task: [
      schedule: "0 3 1,15 * *", # 3AM on the first and 15th of month
      task: &Vae.Authorities.Rncp.Update.update_all/0
    ],
    security_reset_password_task: [
      schedule: "0 4 1 * *", # 4AM on the first of month
      task: &Vae.User.reset_old_users_password/0
    ]
  ], else: []

config :absinthe,
  log: false

config :ex_admin,
  head_template: {VaeWeb.AdminView, "admin_layout.html"},
  repo: Vae.Repo,
  module: VaeWeb,
  modules: [
    Vae.ExAdmin.UserApplication,
    Vae.ExAdmin.AppStatus,
    Vae.ExAdmin.Dashboard,
    Vae.ExAdmin.Certification,
    Vae.ExAdmin.Certifier,
    Vae.ExAdmin.Delegate,
    Vae.ExAdmin.FAQ,
    Vae.ExAdmin.Profession,
    Vae.ExAdmin.Resume,
    Vae.ExAdmin.Rome,
    Vae.ExAdmin.User
  ],
  title: "Avril, la VAE Facile | Admin ",
  override_user_id_session_key: :admin_current_override_user_id

# config :ex_aws,
#   access_key_id: [System.get_env("MINIO_ACCESS_KEY"), :instance_role],
#   secret_access_key: [System.get_env("MINIO_SECRET_KEY"), :instance_role],
#   bucket_name: System.get_env("BUCKET_NAME"),
#   region: "eu-west-3",
#   s3: [
#     scheme: "http://",
#     host: "minio",
#     port: 9000
#     # normalize_path: true
#     # region: "eu-west-3"
#   ]

config :ex_aws, :s3,
  access_key_id: System.get_env("MINIO_ACCESS_KEY"),
  secret_access_key: System.get_env("MINIO_SECRET_KEY"),
  region: "local",
  bucket: System.get_env("BUCKET_NAME"),
  scope: "store",
  scheme: "http://",
  port: 9000,
  host: "minio"

config :gettext, :default_locale, "fr"

config :logger, :console,
  # level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mnesia, :dir, './priv/mnesia'

config :phoenix, :json_library, Jason

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine,
  # If you want to use LiveView
  slimleex: PhoenixSlime.LiveViewEngine,
  md: PhoenixMarkdown.Engine

config :phoenix_markdown, :earmark, %{
  gfm: true,
  # breaks: true,
  pure_links: true
}

config :phoenix_markdown, :server_tags, :all

config :scrivener_html,
  routes_helper: VaeWeb.Router.Helpers,
  view_style: :bootstrap_v4

config :sentry,
  dsn: System.get_env("PHOENIX_SENTRY_DSN"),
  included_environments: [:prod],
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

config :xain, :after_callback, {Phoenix.HTML, :raw}

import_config "#{Mix.env()}.exs"

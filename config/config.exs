# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :vae, ecto_repos: [Vae.Repo]

# Configures the endpoint
config :vae, Vae.Endpoint,
  instrumenters: [NewRelixir.Instrumenters.Phoenix],
  url: [host: "localhost"],
  secret_key_base: "akyL4W53VWMOrzMxWNJP9Y1ofAIkm9dpvp1KLHJhWQUolRUVlCbOdRrr/0UmcjZx",
  render_errors: [view: Vae.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Vae.PubSub, adapter: Phoenix.PubSub.PG2]

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine,
  slimleex: PhoenixSlime.LiveViewEngine # If you want to use LiveView

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :scrivener_html,
  routes_helper: Vae.Router.Helpers,
  view_style: :bootstrap_v4

config :ex_admin,
  head_template: {Vae.AdminView, "admin_layout.html"},
  repo: Vae.Repo.NewRelic,
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

config :xain, :after_callback, {Phoenix.HTML, :raw}

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: Vae.User,
  repo: Vae.Repo.NewRelic,
  module: Vae,
  router: Vae.Router,
  messages_backend: Vae.Coherence.Messages,
  logged_out_url: "/",
  email_from_name: "Avril",
  email_from_email: "avril@pole-emploi.fr",
  opts: [:authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token],
  session_model: Vae.Session,
  session_repo: Vae.Repo,
  schema_key: :id

config :coherence, :layout, {Vae.LayoutView, :app}

config :coherence, Vae.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your api key here"

config :new_relixir,
  application_name: System.get_env("NEWRELIC_APP_NAME"),
  license_key: System.get_env("NEWRELIC_LICENSE_KEY")

config :algolia,
  application_id: System.get_env("ALGOLIA_APP_ID"),
  api_key: System.get_env("ALGOLIA_API_KEY"),
  search_api_key: System.get_env("ALGOLIA_SEARCH_API_KEY")

config :vae,
  places_client: Vae.Places.Client.Algolia,
  search_client: Vae.Search.Client.Algolia,
  algolia_places_app_id: System.get_env("ALGOLIA_PLACES_APP_ID"),
  algolia_places_api_key: System.get_env("ALGOLIA_PLACES_API_KEY"),
  extractor: Vae.Mailer.FileExtractor.CsvExtractor,
  mailer_extractor_limit: 10_000,
  sender: Vae.Mailer.Sender.Mailjet,
  mailjet_template_error_reporting: %{Email: System.get_env("MAILJET_TPL_ERR_REPORTING_EMAIL")},
  mailjet_template_error_deliver: true,
  mailjet: [
    application_submitted_to_delegate_id: 758_379,
    application_submitted_to_user_id: 764_589,
    campaign_template_id: 512_948,
    vae_recap_template_id: 529_420,
    dava_vae_recap_template_id: 878_833,
    asp_vae_recap_template_id: 833_668,
    contact_template_id: 543_455,
    from_email: "contact@avril.pole-emploi.fr",
    from_name: "Avril"
  ],
  statistics: %{
    email_from: "from@email.com",
    email_from_name: "From Name",
    email_to: "to@email.com",
    email_to_name: "To Name"
  }

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

# %% End Coherence Configuration %%
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

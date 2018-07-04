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
  slime: PhoenixSlime.Engine

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
    Vae.ExAdmin.Dashboard,
    Vae.ExAdmin.Certification,
    Vae.ExAdmin.Delegate,
    Vae.ExAdmin.Certifier,
    Vae.ExAdmin.Process
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
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token]

config :coherence, Vae.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your api key here"

config :new_relixir,
  application_name: System.get_env("NEWRELIC_APP_NAME"),
  license_key: System.get_env("NEWRELIC_LICENSE_KEY")

config :algolia,
  application_id: System.get_env("ALGOLIA_APP_ID"),
  api_key: System.get_env("ALGOLIA_API_KEY")

config :vae,
  places_client: Vae.PlacesClient.Algolia,
  algolia_places_apis: %{}

# %% End Coherence Configuration %%
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

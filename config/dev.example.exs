use Mix.Config
# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :vae, Vae.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: ["node_modules/brunch/bin/brunch", "watch", "--stdin", cd: Path.expand("../", __DIR__)]
  ]

# Watch static and templates for browser reloading.
config :vae, Vae.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex|slime|slim)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :vae, Vae.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
  database: "vae_dev",
  hostname: "localhost",
  pool_size: 10

config :vae, Vae.Scheduler, jobs: []

config :vae,
  places_client: Vae.Places.Client.Algolia,
  places_ets_table_name: :places_dev,
  algolia_places_apis:
    %{
      # "PLACES INDEX NAME" => %{
      #   monitoring: "MONITORING API KEY",
      #   search: "seARCH API KEY"
      # }
    },
  mailjet: %{
    campaign_template_id: 070_460,
    vae_recap_template_id: 532_261,
    from_email: "lol@lol.fr",
    override_to: [%{Email: "lol@gmail.com"}, %{Email: "lil@gmail.com"}]
  }

config :mailjex,
  api_base: "https://api.mailjet.com/v3.1",
  public_api_key: "<your public key>",
  private_api_key: "<your private key>",
  development_mode: true

config :vae, Vae.Scheduler,
  timeout: :infinity,
  jobs: [
    # places_task: [
    #  schedule: "*/30 * * * *",
    #  task: {Vae.Places.LoadBalancer, :update_index, []}
    # ],
    # campaign_task: [
    #  timezone: "Europe/Paris",
    #  schedule: "00 10 * * 1",
    #  task: fn ->
    #    Vae.Mailer.extract("priv/fixtures/test_emails_2.csv")
    #    |> Vae.Mailer.send()
    #  end
    # ]
  ]

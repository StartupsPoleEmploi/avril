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

config :vae,
  places_client: Vae.Places.Client.Algolia,
  places_ets_table_name: :places_dev,
  mailjet: %{
    campaign_template_id: 070_460,
    vae_recap_template_id: 532_261,
    contact_template_id: 539_911,
    from_email: "lol@lol.fr",
    from_name: "Avril",
    override_to: [%{Email: "lol@mail.com"}, %{Email: "lil@mail.com"}]
  },
  mailjet_template_error_reporting: %{Email: "reporting@mail.com"},
  mailjet_template_error_deliver: true,
  statistics: %{
    email_from: "from@email.com",
    email_from_name: "From",
    email_to: "to@email.com",
    email_to_name: "To"
  }

config :mailjex,
  api_base: "https://api.mailjet.com/v3.1",
  public_api_key: "<your public key>",
  private_api_key: "<your private key>",
  development_mode: true

config :vae, Vae.Scheduler,
  timeout: :infinity,
  jobs: [
    # campaign_task: [
    #  timezone: "Europe/Paris",
    #  schedule: "00 10 * * 1",
    #  task: &Vae.Mailer.execute/0
    # ],
    #    statistics_task: [
    #      timezone: "Europe/Paris",
    #      schedule: "0 8 14 2 *",
    #      task: fn ->
    #        with pid <- Vae.Statistics.init(),
    #             :ok <- Vae.Statistics.execute(pid),
    #             :ok <- Vae.Statistics.terminate(pid) do
    #          Logger.info("Statistics exported successfully !")
    #        else
    #          err -> Logger.error(fn -> inspect(err) end)
    #        end
    #      end
    #    ]
  ]

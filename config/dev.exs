use Mix.Config
require Logger

config :vae,
  mailjet: [
    override_to: System.get_env("DEV_EMAILS") || "avril@pole-emploi.fr" |> String.split(",") |> Enum.map(&%{Email: &1})
  ]

config :vae, Vae.Endpoint,
  http: [port: 4000],
  url: [host: "localhost"],
  secret_key_base: "akyL4W53VWMOrzMxWNJP9Y1ofAIkm9dpvp1KLHJhWQUolRUVlCbOdRrr/0UmcjZx",
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex|slime|slim)$}
    ]
  ],
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# Configure your database
# config :vae, Vae.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: System.get_env("POSTGRES_USER"),
#   password: System.get_env("POSTGRES_PASSWORD"),
#   database: System.get_env("POSTGRES_DB"),
#   hostname: System.get_env("POSTGRES_HOST"),
#   pool_size: 10,
#   timeout: 60_000


# Unused?
config :vae, Vae.Scheduler,
  timeout: :infinity,
  jobs: [
    campaign_task: [
      timezone: "Europe/Paris",
      schedule: "36 20 * * 5",
      task: fn ->
        Vae.Mailer.extract("priv/fixtures/test_emails_2.csv")
        |> Vae.Mailer.send()
      end
    ],
    statistics_task: [
      timezone: "Europe/Paris",
      schedule: "10 12 14 2 *",
      task: fn ->
        with pid <- Vae.Statistics.init(),
             :ok <- Vae.Statistics.execute(pid),
             :ok <- Vae.Statistics.terminate(pid) do
          Logger.info("Statistics exported successfully !")
        else
          err -> Logger.error(fn -> inspect(err) end)
        end
      end
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20



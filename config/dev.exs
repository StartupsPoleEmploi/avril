use Mix.Config
require Logger

config :vae, VaeWeb.Endpoint,
  http: [port: 4000],
  url: [scheme: "http", host: System.get_env("WHOST") || "localhost", port: 80],
  secret_key_base: "akyL4W53VWMOrzMxWNJP9Y1ofAIkm9dpvp1KLHJhWQUolRUVlCbOdRrr/0UmcjZx",
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(html|js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/vae_web/views/.*(ex)$},
      ~r{lib/vae_web/templates/.*(eex|slime|slim|md)$}
    ]
  ],
  watchers: [
    yarn: [
      "--cwd",
      "./assets",
      "watch"
    ]
  ]

# # Unused?
# config :vae, Vae.Scheduler,
#   timeout: :infinity,
#   jobs: [
#     campaign_task: [
#       timezone: "Europe/Paris",
#       schedule: "30 14 17 7 *",
#       task: &VaeWeb.Mailer.execute/0
#     ],
#     statistics_task: [
#       timezone: "Europe/Paris",
#       schedule: "10 12 14 2 *",
#       task: fn ->
#         with pid <- Vae.Statistics.init(),
#              :ok <- Vae.Statistics.execute(pid),
#              :ok <- Vae.Statistics.terminate(pid) do
#           Logger.info("Statistics exported successfully !")
#         else
#           err -> Logger.error(fn -> inspect(err) end)
#         end
#       end
#     ]
#   ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

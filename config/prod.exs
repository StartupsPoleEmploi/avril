use Mix.Config
require Logger

config :vae, Vae.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: System.get_env("WHOST"), port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

config :vae, Vae.Scheduler,
  jobs: [
    campaign_task: [
      timezone: "Europe/Paris",
      schedule: "30 14 23 7 *",
      task: &Vae.Mailer.execute/0
    ],
    crm_monthly_task: [
      timezone: "Europe/Paris",
      schedule: "15 11 * * *",
      task: fn ->
        with pid <- Vae.Crm.init(),
             :ok <- Vae.Crm.execute(pid, Date.utc_today()),
             :ok <- Vae.Crm.terminate(pid) do
          Logger.info("Monthly emails sent successfuly !")
        else
          err -> Logger.error(fn -> inspect(err) end)
        end
      end
    ],
    afpa_refresh: [
      timezone: "Europe/Paris",
      schedule: "0 5 * * *",
      task: &Vae.Meetings.refresh_afpa_meetings/0
    ]
  ]

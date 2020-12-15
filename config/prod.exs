use Mix.Config
require Logger

config :vae, VaeWeb.Endpoint,
  http: [port: System.get_env("PORT") || 4000],
  url: [scheme: "https", host: System.get_env("WHOST"), port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

# config :vae, Vae.Scheduler,
#   jobs: [
#     registered_campaign_task: [
#       schedule: "30 10 * * 2",
#       task: fn () ->
#         Vae.CampaignDiffuser.Handler.execute_registered(Vae.Date.last_monday())
#       end
#     ],
#     new_registered_campaign_task: [
#       schedule: "30 14 * * 2",
#       task: fn () ->
#         Vae.CampaignDiffuser.Handler.execute_new_registered(Vae.Date.last_monday())
#       end
#     ]
#   ]

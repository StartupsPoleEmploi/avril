use Mix.Config
require Logger

config :vae, Vae.Endpoint,
  http: [port: {:system, "PORT"} || 4000],
  url: [scheme: "https", host: System.get_env("WHOST"), port: 443],
  # force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :debug


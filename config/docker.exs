use Mix.Config

config :pdf_generator,
  wkhtml_path: "/bin/wkhtmltopdf"

config :vae, Vae.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [scheme: "http", host: System.get_env("WHOST"), port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Do not print debug messages in production
config :logger, level: :info

config :vae, Vae.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: false

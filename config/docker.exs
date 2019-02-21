use Mix.Config

config :pdf_generator,
  wkhtml_path: "/bin/wkhtmltopdf"

config :vae, Vae.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [scheme: "http", host: System.get_env("WHOST"), port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE") || "9489b3eee4eccf317ed77407553e8adc97baca7c74dc7ee33cd93e4c8b69477eea66eaedeb18af0be2679887c7c69c0a28c0fded0a71ea472a8c4laalal19cb"

# Do not print debug messages in production
config :logger, level: :info

config :vae, Vae.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  username: "postgres",
  password: System.get_env("POSTGRES_PASSWORD"),
  database: "postgres",
  hostname: "avril-postgresql",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

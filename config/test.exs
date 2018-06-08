use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :vae, Vae.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
# config :vae, Vae.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "vae",
#   password: "",
#   database: "vae_test",
#   hostname: "localhost",
#   pool: Ecto.Adapters.SQL.Sandbox

# Configure your database
config :vae, Vae.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
  database: "vae_dev",
  hostname: "localhost",
  pool_size: 10

config :vae,
  places_client: Vae.PlacesClient.InMemory,
  algolia_places_apis: %{
    "foo" => "123456",
    "bar" => "098765",
    "baz" => "789012"
  }


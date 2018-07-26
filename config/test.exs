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
  database: "vae_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :vae,
  places_client: Vae.Places.Client.InMemory,
  places_ets_table_name: :places_test,
  algolia_places_apis: %{
    "foo" => %{
      monitoring: "123456",
      search: "foo_search"
    },
    "bar" => %{
      monitoring: "098765",
      search: "bar_search"
    },
    "baz" => %{
      monitoring: "789012",
      search: "baz_search"
    }
  }

config :mailjex,
  api_base: "https://api.mailjet.com/v3.1",
  public_api_key: "myApiKey",
  private_api_key: "MyPrivateKey",
  development_mode: true

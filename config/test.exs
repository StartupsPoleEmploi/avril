use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :vae, VaeWeb.Endpoint,
  http: [port: 4001],
  url: [scheme: "http", host: System.get_env("WHOST") || "localhost", port: 80],
  server: false,
  secret_key_base: "CPBIsZXHKo41NCrQGS/S3zaVhZrPeH/EtkS/nR2+uf7gFQaEXpd1SM92za61ZO1V"

# Print only warnings and errors during test
config :logger, :console, format: "[$level] $message\n"

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
  pool: Ecto.Adapters.SQL.Sandbox

config :vae,
  meetings_state_holder: Vae.Meetings.StateHolderMock,
  places_ets_table_name: :places_test,
  mailjet: %{
    from_email: "x@gmail.com",
    # campaign_template_id: 475_460,
    # from_email: "contact@avril.pole-emploi.fr"
    override_to: [%{Email: "x@gmail.com"}]
  }

config :vae, VaeWeb.Mailer, adapter: Swoosh.Adapters.Test

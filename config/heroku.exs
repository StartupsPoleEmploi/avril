use Mix.Config

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
#
# You should also configure the url host to something
# meaningful, we use this information when generating URLs.
#
# Finally, we also include the path to a manifest
# containing the digested version of static files. This
# manifest is generated by the mix phoenix.digest task
# which you typically run after static files are built.

config :vae, Vae.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [scheme: "https", host: System.get_env("WHOST"), port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Do not print debug messages in production
config :logger, level: :info

config :vae,
  mailjet: %{
    application_submitted_to_delegate_id: 758_379,
    application_submitted_to_user_id: 764_589,
    campaign_template_id: 070_460,
    vae_recap_template_id: 532_261,
    contact_template_id: 539_911,
    from_email: "avril@pole-emploi.fr",
    from_name: "Avril",
    override_to:
      Enum.map(String.split(System.get_env("MAILJET_PUBLIC_API_KEY"), ","), &%{Email: &1})
  },
  mailjet_template_error_reporting:
    List.first(
      Enum.map(String.split(System.get_env("MAILJET_PUBLIC_API_KEY"), ","), &%{Email: &1})
    ),
  mailjet_template_error_deliver: true

config :vae, Vae.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

config :vae,
  authentication: [
    client_id: System.get_env("PE_CONNECT_CLIENT_ID"),
    client_secret: System.get_env("PE_CONNECT_CLIENT_SECRET"),
    site: "https://authentification-candidat.pole-emploi.fr",
    authorize_url: "/connexion/oauth2/authorize",
    redirect_uri: "http://#{System.get_env("WHOST")}/pole-emploi/callback"
  ]

config :mailjex,
  api_base: "https://api.mailjet.com/v3.1",
  public_api_key: System.get_env("MAILJET_PUBLIC_API_KEY"),
  private_api_key: System.get_env("MAILJET_PRIVATE_API_KEY"),
  development_mode: false

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :vae, Vae.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :vae, Vae.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :vae, Vae.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
# import_config "prod.secret.exs"

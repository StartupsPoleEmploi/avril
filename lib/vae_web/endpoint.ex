defmodule VaeWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :vae

  plug(RemoteIp)

  # socket("/socket", VaeWeb.UserSocket)
  # socket "/socket", VaeWeb.UserSocket,
  #   websocket: true # or list of options
  # longpoll: [check_origin: ...]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :vae,
    gzip: true,
    only: ~w(css fonts images icons js),
    only_matching: ~w(favicon apple-touch-icon robots)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison,
    length: 8_000_000,
    read_length: 1_000_000,
    read_timeout: 15_000
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    store: :cookie,
    key: "_vae_key",
    signing_salt: "2nvfILl2"
  )

  # After plug Plug.Session
  plug(
    Pow.Plug.Session,
    otp_app: :vae,
    session_ttl_renewal: :timer.minutes(1),
    credentials_cache_store: {Pow.Store.CredentialsCache, ttl: :timer.minutes(15)}
  )

  plug(PowPersistentSession.Plug.Cookie)

  plug(VaeWeb.Router)
end

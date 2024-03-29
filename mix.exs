defmodule Vae.Mixfile do
  use Mix.Project

  def project do
    [
      app: :vae,
      version: "1.3.0",
      elixir: "~> 1.8.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Vae.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 4.1.0"},
      {:phoenix_html, "~> 2.13.3"},
      {:ecto_sql, "~> 3.6.2"},
      {:postgrex, "~> 0.15.3"},
      {:geo_postgis, "~> 3.1"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:pow, "~> 1.0.26"},
      {:bcrypt_elixir, "~> 1.1.1"},
      {:sweet_xml, "~> 0.6.5"},
      {:csv, "~> 2.3.1"},
      {:scrivener_ecto, "~> 2.0"},
      {:scrivener_html, "~> 1.8"},
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.5"},
      {:floki, "~> 0.21.0"},
      # TODO: remove dependency: not needed anymore
      {:poison, "~> 3.1", override: true},
      {:phoenix_slime, "~> 0.12.0"},
      # {:ex_admin, path: "../ex_admin", in_umbrella: true}, # When debugging ex_admin locally
      {:ex_admin, github: "augnustin/ex_admin"},
      {:remote_ip, "~> 0.1.0"},
      {:flow, "~> 0.14.0"},
      {:timex, "~> 3.7.5"},
      {:elixir_uuid, "~> 1.2"},
      {:persistent_ets, "~> 0.1.0"},
      {:pdf_generator, ">=0.5.0"},
      {:observer_cli, "~> 1.4"},
      {:filterable, "~> 0.7.0"},
      {:oauth2, "~> 0.9"},
      {:inflex, "~> 1.10.0"},
      {:swoosh, "~> 0.25"},
      {:phoenix_swoosh, "~> 0.2"},
      {:plug_static_index_html, "~> 1.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sentry, "~> 6.4"},
      {:phoenix_markdown, "~> 1.0"},
      {:health_checkup, "~> 0.1.0"},
      {:absinthe, "~> 1.4.0"},
      {:absinthe_plug, "~> 1.4"},
      {:quantum, "~> 3.0"},
      {:struct_access, "~> 1.1.2"},
      {:html_entities, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:ex_machina, "~> 2.3", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      sentry_recompile: ["deps.compile sentry --force", "compile"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
      # test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end

defmodule Vae.Mixfile do
  use Mix.Project

  def project do
    [
      app: :vae,
      version: "0.9.6",
      elixir: "~> 1.2",
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
      mod: {Vae, []},
      applications: [
        :phoenix,
        :phoenix_pubsub,
        :phoenix_html,
        :cowboy,
        :logger,
        :gettext,
        :phoenix_ecto,
        :postgrex,
        :phoenix_slime,
        :scrivener_ecto,
        :scrivener_html,
        :httpoison,
        :coherence,
        :sentry,
        :algolia,
        :persistent_ets,
        :pdf_generator,
        :observer_cli,
        :oauth2,
        :swoosh,
        :ex_aws,
        :hackney,
        :poison
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.3.0"},
      {:postgrex, "~> 0.13.0"},
      {:phoenix_html, "~> 2.13.3"},
      {:plug_cowboy, "~> 2.0"},
      {:distillery, "~> 1.4"},
      {:sweet_xml, "~> 0.6.5"},
      {:csv, "~> 2.0.0"},
      {:scrivener_ecto, "~> 1.0"},
      {:scrivener_html, "~> 1.8"},
      {:jason, "~> 1.0"},
      {:httpoison, "~> 1.5"},
      {:floki, "~> 0.21.0"},
      # TODO: remove dependency: not needed anymore
      {:poison, "~> 3.0", override: true},
      {:phoenix_slime, "~> 0.12.0"},
      # {:ex_admin, path: "../ex_admin", in_umbrella: true}, # When debugging ex_admin locally
      {:ex_admin, github: "augnustin/ex_admin"},
      {:coherence, "~> 0.5.2"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:algolia, "~> 0.8.0"},
      {:remote_ip, "~> 0.1.0"},
      {:flow, "~> 0.14.0"},
      {:quantum, "~> 2.2"},
      {:timex, "~> 3.6.1"},
      {:elixir_uuid, "~> 1.2"},
      {:persistent_ets, "~> 0.1.0"},
      {:pdf_generator, ">=0.5.0"},
      {:observer_cli, "~> 1.4"},
      {:filterable, "~> 0.7.0"},
      {:oauth2, "~> 0.9"},
      {:inflex, "~> 1.10.0"},
      {:swoosh,
       github: "nresni/swoosh",
       ref: "b4188c3913486e41f17b0f21cca2b29913b54f53",
       override: true},
      # {:swoosh, "~> 0.24.3"},
      {:phoenix_swoosh, "~> 0.2"},
      {:plug_static_index_html, "~> 1.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sentry, "~> 6.4"},
      {:cors_plug, "~> 2.0"},
      {:phoenix_markdown, "~> 1.0"},
      {:health_checkup, "~> 0.1.0"}
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

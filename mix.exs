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
        :phoenix_form_awesomplete,
        :httpoison,
        :coherence,
        :new_relixir,
        :algolia,
        :mailjex,
        :persistent_ets
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
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.0"},
      {:postgrex, "~> 0.13.5"},
      {:phoenix_html, "~> 2.6"},
      {:gettext, "0.13.1"},
      {:cowboy, "~> 1.0"},
      {:distillery, "~> 1.4"},
      {:sweet_xml, "~> 0.6.5"},
      {:csv, "~> 2.0.0"},
      {:scrivener_ecto, "~> 1.0"},
      {:scrivener_html, "~> 1.7"},
      {:phoenix_form_awesomplete, "~> 0.1"},
      {:httpoison, "~> 0.13"},
      {:poison, "~> 3.0", override: true},
      {:phoenix_slime, "~> 0.8.0"},
      {:ex_admin, github: "nresni/ex_admin", tag: "0.8.3"},
      {:coherence, "~> 0.4.0"},
      {:new_relixir, "~> 0.4.1"},
      {:floki, "~> 0.19.0", only: :dev},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:algolia, "~> 0.6.5"},
      {:remote_ip, "~> 0.1.0"},
      {:flow, "~> 0.13"},
      {:quantum, "~> 2.2"},
      {:timex, "~> 3.0"},
      {:navigation_history, "~> 0.0"},
      {:mailjex, "~> 0.1.4"},
      {:plug, "1.5.0"},
      {:uuid, "~> 1.1"},
      {:persistent_ets, "~> 0.1.0"}
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
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
      # test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end

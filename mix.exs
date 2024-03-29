defmodule Abbr.MixProject do
  use Mix.Project

  def project do
    [
      app: :abbr,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(Mix.env())
    ]
  end

  def application do
    [
      mod: {Abbr.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :logger_file_backend
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer(:test) do
    [
      plt_add_apps: [:ex_unit, :mix],
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp dialyzer(_) do
    [
      plt_add_apps: [:mix]
    ]
  end

  defp deps do
    [
      {:confex, "~> 3.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:gettext, "~> 0.23"},
      {:jason, "~> 1.4"},
      {:libcluster, "~> 3.3"},
      {:local_cluster, "~> 1.2", only: [:dev, :test]},
      {:logger_file_backend, "~> 0.0.13"},
      {:memento, github: "sheharyarn/memento"},
      {:phoenix, "~> 1.7"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.6"},
      {:schism, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      test: ["test --no-start"]
    ]
  end
end

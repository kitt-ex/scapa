defmodule Scapa.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :scapa,
      name: "Scapa",
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/brunvez/scapa",
      description:
        "A static code analysis tool focused on keeping documentation up to date with the related code.",
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.13", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:lcov_ex, "~> 0.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Scapa",
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  defp package do
    [
      maintainers: ["Bruno Vezoli", "Matias Gutierrez"],
      licenses: ["MIT"],
      files:
        Enum.reject(
          Path.wildcard("lib/**/*.ex"),
          &(&1 == "lib/mix/tasks/coverage_report.ex")
        ) ++ ~w(.formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      links: %{
        "GitHub" => "https://github.com/brunvez/scapa",
        "Changelog" => "https://github.com/brunvez/scapa/blob/master/CHANGELOG.md"
      }
    ]
  end
end

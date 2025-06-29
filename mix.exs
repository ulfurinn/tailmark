defmodule Tailmark.MixProject do
  use Mix.Project

  def project do
    [
      app: :tailmark,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:html_entities, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.9"}
    ]
  end
end

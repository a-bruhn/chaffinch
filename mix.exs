defmodule Chaffinch.MixProject do
  use Mix.Project

  def project do
    [
      app: :chaffinch,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Chaffinch, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ratatouille, "~> 0.5.1"}
      # {:distillery, "~> 2.1.1"}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end

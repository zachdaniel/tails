defmodule Tails.MixProject do
  use Mix.Project

  def project do
    [
      app: :tails,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      sobelow: "sobelow --skip",
      credo: "credo --strict"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:ex_check, "~> 0.12.0", only: :dev},
      {:credo, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:sobelow, ">= 0.0.0", only: :dev, runtime: false},
      {:git_ops, "~> 2.5", only: :dev},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:parse_trans, "3.3.0", only: [:dev, :test], override: true},
      {:elixir_sense, github: "elixir-lsp/elixir_sense", only: [:test, :dev, :docs]}
    ]
  end
end

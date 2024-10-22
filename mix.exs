defmodule TeslaMiddlewareThrottle.MixProject do
  use Mix.Project

  def project do
    [
      app: :tesla_middleware_throttle,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Tesla.Middleware.Throttle.Application, []}
    ]
  end

  defp deps do
    [
      {:decimal, "~> 2.1"},
      {:mox, "~> 1.2", only: [:dev, :test]},
      {:tesla, "~> 1.12"}
    ]
  end

  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_env), do: ["lib", "test/support"]
end

defmodule TeslaMiddlewareThrottle.MixProject do
  use Mix.Project

  def project do
    [
      app: :tesla_middleware_throttle,
      version: "0.1.0",
      elixir: "~> 1.15",
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
    []
  end
end

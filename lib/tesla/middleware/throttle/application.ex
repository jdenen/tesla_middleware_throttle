defmodule Tesla.Middleware.Throttle.Application do
  @moduledoc false
  use Application

  alias Tesla.Middleware.Throttle

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, name: Throttle.Registry, keys: :unique},
      {DynamicSupervisor, name: Throttle.DynSup}
    ]

    opts = [strategy: :one_for_one, name: TeslaMiddlewareThrottle.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

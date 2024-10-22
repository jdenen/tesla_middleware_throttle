defmodule Tesla.Middleware.Throttle do
  @behaviour Tesla.Middleware

  alias Tesla.Middleware.Throttle

  @impl true
  def call(env, next, opts) do
    name = Keyword.get(opts, :name, Throttle.Server)
    supervisor = Keyword.get(opts, :supervisor, Throttle.DynSup)

    with [] <- Registry.lookup(Throttle.Registry, name),
         {:ok, pid} <- DynamicSupervisor.start_child(supervisor, {Throttle.Server, opts}) do
      maybe_throttle(env, next, pid)
    else
      [{pid, _}] -> maybe_throttle(env, next, pid)
      {:ok, pid, _info} -> maybe_throttle(env, next, pid)
      {:error, {:already_started, pid}} -> maybe_throttle(env, next, pid)
      error -> error
    end
  end

  defp maybe_throttle(env, next, pid) do
    case Throttle.Server.throttle(pid) do
      0 -> Tesla.run(env, next)
      ms -> {:throttle, ms}
    end
  end
end

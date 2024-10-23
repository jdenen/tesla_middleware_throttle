defmodule Tesla.Middleware.Throttle do
  @moduledoc """
  `Tesla.Middleware` implementation for a sliding window throttle. Until requests exceed
  the configured threshold within the sliding window, this middleware does nothing.

  When requests exceed the threshold, this middleware returns `{:throttle, ms}`, where `ms`
  is the number of milliseconds the caller should wait before trying again.

  ## Sliding window

  A two-element tuple specifies the threshold of requests within a rolling period of millseconds before
  throttling occurs. A window of no more than 10 requests within 10 seconds would look like `{10, 10_000}`.

  In this example, requests counted against the threshold fall off as ten seconds pass.

  ## Named Throttles

  By default, this middleware stands up a single `Throttle.Server`, and all requests made
  through the middleware will be throttled together. Tesla clients can name their `Throttle.Server`
  to avoid contamination across different request types.

      Tesla.client([{Throttle, name: SlowApi, window: {1, 300_000}}], Tesla.Adapter)

      Tesla.client([{Throttle, name: FastApi, window: {10_000, 1_000}}], Tesla.Adapter)

  ## Options

  - `:window`: Required. A two element tuple of a request threshold and milliseconds. For example, 10 requests
    per second before throttling would be `window: {10, 1_000}`.
  - `:name`: Optional. The name of the throttle. Defaults to `Tesla.Middleware.Throttle.Server`.
  - `:registry`: Optional. The name of the registry to check for throttle server processes. Defaults to
    `Tesla.Middleware.Throttle.Registry`.
  - `:supervisor`: Optional. The `DynamicSupervisor` under which the throttle server starts. Defaults to
    `Tesla.Middleware.Throttle.DynSup`.
  """
  @behaviour Tesla.Middleware

  alias Tesla.Middleware.Throttle

  @impl true
  def call(env, next, opts) do
    name = Keyword.get(opts, :name, Throttle.Server)
    registry = Keyword.get(opts, :registry, Throttle.Registry)
    supervisor = Keyword.get(opts, :supervisor, Throttle.DynSup)

    with [] <- Registry.lookup(registry, name),
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

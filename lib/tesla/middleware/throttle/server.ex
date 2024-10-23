defmodule Tesla.Middleware.Throttle.Server do
  use GenServer

  alias Tesla.Middleware.Throttle

  @spec throttle(GenServer.server()) :: non_neg_integer
  def throttle(server) do
    GenServer.call(server, :throttle)
  end

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via(opts))
  end

  @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  @impl true
  def init(opts) do
    state = %{
      value: 0,
      window: Keyword.fetch!(opts, :window)
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:throttle, _from, state) do
    new_value = state.value + 1

    {:reply, get_ms(new_value, state.window), %{state | value: new_value},
     {:continue, :decrement}}
  end

  @impl true
  def handle_continue(:decrement, %{window: {_, ms}} = state) do
    Process.send_after(self(), :decrement, ms)
    {:noreply, state}
  end

  @impl true
  def handle_info(:decrement, state) do
    {:noreply, %{state | value: state.value - 1}}
  end

  defp get_ms(value, {hold, ms}) when value > hold do
    # TODO better way to do this?
    value
    |> Decimal.div(hold)
    |> Decimal.sub(1)
    |> Decimal.mult(ms)
    |> Decimal.abs()
    |> Decimal.round()
    |> Decimal.min(ms)
    |> Decimal.to_integer()
  end

  defp get_ms(_value, _window), do: 0

  defp via(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    registry = Keyword.get(opts, :registry, Throttle.Registry)
    {:via, Registry, {registry, name}}
  end
end

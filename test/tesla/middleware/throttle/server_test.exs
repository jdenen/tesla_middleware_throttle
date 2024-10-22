defmodule Tesla.Middleware.Throttle.ServerTest do
  use ExUnit.Case

  alias Tesla.Middleware.Throttle

  describe "start_link/1" do
    test "started with default name" do
      assert {:ok, pid} = start_supervised({Throttle.Server, window: {10, 10}})
      assert [{^pid, _}] = Registry.lookup(Throttle.Registry, Throttle.Server)
    end

    test "started with given name" do
      assert {:ok, foo} = start_supervised({Throttle.Server, name: Foo, window: {10, 10}})
      assert {:ok, bar} = start_supervised({Throttle.Server, name: Bar, window: {10, 10}})

      assert [{^foo, _}] = Registry.lookup(Throttle.Registry, Foo)
      assert [{^bar, _}] = Registry.lookup(Throttle.Registry, Bar)
    end
  end

  describe "throttle/1" do
    setup ctx do
      window = Map.get(ctx, :window, {2, 1_000})
      {:ok, pid} = start_supervised({Throttle.Server, window: window})

      [pid: pid]
    end

    test "returns 0 unless throttling necessary", ctx do
      assert Throttle.Server.throttle(ctx.pid) == 0
    end

    test "returns ms if throttling necessary", ctx do
      assert Throttle.Server.throttle(ctx.pid) == 0
      assert Throttle.Server.throttle(ctx.pid) == 0
      assert Throttle.Server.throttle(ctx.pid) == 500
    end

    test "maximum throttle cannot exceed window", ctx do
      assert Throttle.Server.throttle(ctx.pid) == 0
      assert Throttle.Server.throttle(ctx.pid) == 0
      assert Throttle.Server.throttle(ctx.pid) == 500
      assert Throttle.Server.throttle(ctx.pid) == 1_000
      assert Throttle.Server.throttle(ctx.pid) == 1_000
      assert Throttle.Server.throttle(ctx.pid) == 1_000
    end

    @tag window: {1, 10}
    test "sliding window renders throttling unnecessary", ctx do
      assert Throttle.Server.throttle(ctx.pid) == 0
      assert Throttle.Server.throttle(ctx.pid) == 10

      :timer.sleep(11)
      assert Throttle.Server.throttle(ctx.pid) == 0

      :timer.sleep(11)
      assert Throttle.Server.throttle(ctx.pid) == 0
    end
  end
end

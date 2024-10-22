defmodule Tesla.Middleware.ThrottleTest do
  use ExUnit.Case

  import Mox

  alias Tesla.Middleware.Throttle

  setup [:set_mox_global, :verify_on_exit!]

  describe "call/3" do
    setup ctx do
      stub(TeslaMock, :call, fn %{url: "/url"} = env, _ ->
        {:ok, %{env | status: 200, body: "ok"}}
      end)

      window = Map.get(ctx, :window, {2, 1_000})
      {:ok, pid} = start_supervised({Throttle.Server, window: window})

      [
        client: Tesla.client([{Tesla.Middleware.BaseUrl, ""}, {Throttle, []}]),
        pid: pid
      ]
    end

    test "starts server if not already started" do
      start_supervised({DynamicSupervisor, name: TestSup})

      throttle = {Throttle, name: Test, supervisor: TestSup, window: {2, 1_000}}
      client = Tesla.client([{Tesla.Middleware.BaseUrl, ""}, throttle], TeslaMock)

      assert {:ok, _} = Tesla.get(client, "/url")

      assert [{pid, _}] = Registry.lookup(Throttle.Registry, Test)
      assert Process.alive?(pid)
    end

    test "does not halt unthrottled request", ctx do
      expect(TeslaMock, :call, fn %{url: "/unthrottled"} = env, _ ->
        {:ok, %{env | status: 200, body: "ok"}}
      end)

      assert {:ok, _} = Tesla.get(ctx.client, "/unthrottled")
    end

    @tag window: {1, 1_000}
    test "returns ms to wait for throttling", ctx do
      expect(TeslaMock, :call, fn %{url: "/throttled"} = env, _ ->
        {:ok, %{env | status: 200, body: "ok"}}
      end)

      assert {:ok, _} = Tesla.get(ctx.client, "/throttled")
      assert {:throttle, 1_000} = Tesla.get(ctx.client, "/throttled")
    end
  end
end

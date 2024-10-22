defmodule TeslaMiddlewareThrottleTest do
  use ExUnit.Case
  doctest TeslaMiddlewareThrottle

  test "greets the world" do
    assert TeslaMiddlewareThrottle.hello() == :world
  end
end

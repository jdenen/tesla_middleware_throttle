defmodule StaticResponse do
  @moduledoc """
  A static response adapter for local development/testing.
  """
  @behaviour Tesla.Adapter

  def call(_env, _opts), do: {:ok, %Tesla.Env{status: 200}}
end

defmodule TestClient do
  def get do
    Tesla.get(client(), "/")
  end

  def client do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, ""},
        {Tesla.Middleware.Throttle, window: {1_000, 60_000}}
      ],
      StaticResponse
    )
  end
end

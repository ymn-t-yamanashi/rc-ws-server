defmodule RcCarWs.Socket do
  @moduledoc false

  @behaviour :cowboy_websocket

  alias RcCarWs.ClientRegistry

  @impl true
  def init(request, _state), do: {:cowboy_websocket, request, %{}}

  @impl true
  def websocket_init(state) do
    :ok = ClientRegistry.register(self())
    {:reply, {:text, Jason.encode!(%{type: "server_ready"})}, state}
  end

  @impl true
  def websocket_handle({:text, payload}, state) do
    set_role_from_hello(payload)
    :ok = ClientRegistry.broadcast(self(), payload)
    {:ok, state}
  end

  def websocket_handle(_frame, state), do: {:ok, state}

  @impl true
  def websocket_info({:ws_broadcast, payload}, state) do
    {:reply, {:text, payload}, state}
  end

  def websocket_info(_message, state), do: {:ok, state}

  defp set_role_from_hello(payload) do
    case Jason.decode(payload) do
      {:ok, %{"type" => "hello", "role" => role}}
      when role in ["device", "xrift"] ->
        :ok = ClientRegistry.set_role(self(), role)

      _ ->
        :ok
    end
  end

  @impl true
  def terminate(_reason, _request, _state) do
    ClientRegistry.unregister(self())
    :ok
  end
end

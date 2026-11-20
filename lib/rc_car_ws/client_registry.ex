defmodule RcCarWs.ClientRegistry do
  @moduledoc "Tracks WebSocket processes and forwards messages between them."

  use GenServer

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_arg), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @spec register(pid()) :: :ok
  def register(pid), do: GenServer.call(__MODULE__, {:register, pid})

  @spec unregister(pid()) :: :ok
  def unregister(pid), do: GenServer.cast(__MODULE__, {:unregister, pid})

  @spec set_role(pid(), binary()) :: :ok
  def set_role(pid, role), do: GenServer.call(__MODULE__, {:set_role, pid, role})

  @spec broadcast(pid(), binary()) :: :ok
  def broadcast(sender, payload), do: GenServer.cast(__MODULE__, {:broadcast, sender, payload})

  @impl true
  def init(_arg), do: {:ok, %{clients: %{}, vdo_view: nil}}

  @impl true
  def handle_call({:register, pid}, _from, state) do
    clients = Map.put(state.clients, pid, %{role: nil})

    if device_connected?(clients) do
      send(pid, {:ws_broadcast, Jason.encode!(%{type: "device_status", connected: true})})
    end

    {:reply, :ok, %{state | clients: clients}}
  end

  @impl true
  def handle_call({:set_role, pid, role}, _from, state) do
    old_role = get_in(state.clients, [pid, :role])
    clients = update_in(state.clients, [pid, :role], fn _ -> role end)

    if role == "device" and old_role != "device" do
      broadcast_to_others(clients, pid, Jason.encode!(%{type: "device_status", connected: true}))
    end

    if role == "xrift" and old_role != "xrift" and is_binary(state.vdo_view) do
      send(pid, {:ws_broadcast, state.vdo_view})
    end

    {:reply, :ok, %{state | clients: clients}}
  end

  @impl true
  def handle_cast({:unregister, pid}, state) do
    was_device = get_in(state.clients, [pid, :role]) == "device"

    {:noreply, %{state | clients: Map.delete(state.clients, pid)}}
    |> maybe_announce_disconnect(was_device, pid)
  end

  @impl true
  def handle_cast({:broadcast, sender, payload}, state) do
    {state, should_broadcast} = remember_vdo_view(state, payload)

    if should_broadcast do
      broadcast_payload(state.clients, sender, payload)
    end

    {:noreply, state}
  end

  defp device_connected?(clients),
    do: Enum.any?(clients, fn {_pid, state} -> state.role == "device" end)

  defp remember_vdo_view(state, payload) do
    case Jason.decode(payload) do
      {:ok, %{"type" => "vdo_view_set", "url" => url}} when is_binary(url) ->
        if current_vdo_url(state.vdo_view) == url do
          {state, false}
        else
          {%{state | vdo_view: payload}, true}
        end

      _ ->
        {state, true}
    end
  end

  defp current_vdo_url(nil), do: nil

  defp current_vdo_url(payload) do
    case Jason.decode(payload) do
      {:ok, %{"type" => "vdo_view_set", "url" => url}} when is_binary(url) -> url
      _ -> nil
    end
  end

  defp broadcast_payload(clients, sender, payload) do
    case Jason.decode(payload) do
      {:ok, %{"type" => "vdo_view_set"}} ->
        broadcast_to_xrift_clients(clients, sender, payload)

      _ ->
        broadcast_to_others(clients, sender, payload)
    end
  end

  defp broadcast_to_others(clients, sender, payload) do
    clients
    |> Map.keys()
    |> Enum.reject(&(&1 == sender))
    |> Enum.each(&send(&1, {:ws_broadcast, payload}))
  end

  defp broadcast_to_xrift_clients(clients, sender, payload) do
    clients
    |> Enum.filter(fn {pid, state} -> pid != sender and state.role == "xrift" end)
    |> Enum.each(fn {pid, _state} -> send(pid, {:ws_broadcast, payload}) end)
  end

  defp maybe_announce_disconnect({:noreply, state}, false, _pid), do: {:noreply, state}

  defp maybe_announce_disconnect({:noreply, state}, true, pid) do
    broadcast_to_others(
      state.clients,
      pid,
      Jason.encode!(%{type: "device_status", connected: false})
    )

    {:noreply, state}
  end
end

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
  def init(clients), do: {:ok, clients}

  @impl true
  def handle_call({:register, pid}, _from, clients) do
    clients = Map.put(clients, pid, %{role: nil})

    if device_connected?(clients) do
      send(pid, {:ws_broadcast, Jason.encode!(%{type: "device_status", connected: true})})
    end

    {:reply, :ok, clients}
  end

  @impl true
  def handle_call({:set_role, pid, role}, _from, clients) do
    old_role = get_in(clients, [pid, :role])
    clients = update_in(clients, [pid, :role], fn _ -> role end)

    if role == "device" and old_role != "device" do
      broadcast_to_others(clients, pid, Jason.encode!(%{type: "device_status", connected: true}))
    end

    {:reply, :ok, clients}
  end

  @impl true
  def handle_cast({:unregister, pid}, clients) do
    was_device = get_in(clients, [pid, :role]) == "device"

    {:noreply, Map.delete(clients, pid)}
    |> maybe_announce_disconnect(was_device, pid)
  end

  @impl true
  def handle_cast({:broadcast, sender, payload}, clients) do
    broadcast_to_others(clients, sender, payload)

    {:noreply, clients}
  end

  defp device_connected?(clients),
    do: Enum.any?(clients, fn {_pid, state} -> state.role == "device" end)

  defp broadcast_to_others(clients, sender, payload) do
    clients
    |> Map.keys()
    |> Enum.reject(&(&1 == sender))
    |> Enum.each(&send(&1, {:ws_broadcast, payload}))
  end

  defp maybe_announce_disconnect({:noreply, clients}, false, _pid), do: {:noreply, clients}

  defp maybe_announce_disconnect({:noreply, clients}, true, pid) do
    broadcast_to_others(clients, pid, Jason.encode!(%{type: "device_status", connected: false}))
    {:noreply, clients}
  end
end

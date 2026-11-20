defmodule RcCarWs.Application do
  @moduledoc false

  use Application

  @listener :rc_car_ws_listener

  @impl true
  def start(_type, _args) do
    children = [
      {RcCarWs.ClientRegistry, []}
    ]

    {:ok, supervisor} =
      Supervisor.start_link(children, strategy: :one_for_one, name: RcCarWs.Supervisor)

    dispatch =
      :cowboy_router.compile([
        {:_,
         [
           {"/health", RcCarWs.Health, []},
           {"/ws", RcCarWs.Socket, []}
         ]}
      ])

    transport_options = [
      {:ip, {0, 0, 0, 0}},
      {:port, port()}
    ]

    case :cowboy.start_clear(@listener, transport_options, %{env: %{dispatch: dispatch}}) do
      {:ok, _pid} ->
        {:ok, supervisor}

      {:error, reason} ->
        Supervisor.stop(supervisor)
        {:error, reason}
    end
  end

  @impl true
  def stop(_state) do
    :cowboy.stop_listener(@listener)
  end

  defp port do
    System.get_env("PORT", "4000")
    |> String.to_integer()
  end
end

defmodule RcCarWs.Protocol do
  @moduledoc "Validation for the small shared XRift/AtomVM message protocol."

  @type message :: map()

  @spec decode(binary()) :: {:ok, message()} | {:error, atom()}
  def decode(payload) do
    with {:ok, message} <- Jason.decode(payload),
         :ok <- validate(message) do
      {:ok, message}
    else
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_message}
    end
  end

  @spec encode(map()) :: binary()
  def encode(message), do: Jason.encode!(message)

  @spec error(atom()) :: binary()
  def error(code), do: encode(%{type: "error", code: Atom.to_string(code)})

  defp validate(%{"type" => "hello", "role" => role}) when role in ["device", "xrift"], do: :ok

  defp validate(%{"type" => type, "left" => left, "right" => right})
       when type in ["motor_set", "motor_state"] and left in [-1, 0, 1] and right in [-1, 0, 1],
       do: :ok

  defp validate(_message), do: {:error, :invalid_message}
end

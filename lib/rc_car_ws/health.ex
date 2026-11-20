defmodule RcCarWs.Health do
  @moduledoc false

  @behaviour :cowboy_handler

  @impl true
  def init(request, state) do
    request =
      :cowboy_req.reply(
        200,
        %{<<"content-type">> => <<"application/json; charset=utf-8">>},
        ~s({"status":"ok"}),
        request
      )

    {:ok, request, state}
  end
end

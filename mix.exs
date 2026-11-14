defmodule RcCarWs.MixProject do
  use Mix.Project

  def project do
    [
      app: :rc_car_ws,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RcCarWs.Application, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.12"},
      {:jason, "~> 1.4"}
    ]
  end
end

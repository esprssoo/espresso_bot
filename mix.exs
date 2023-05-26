defmodule EspressoBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :espresso_bot,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EspressoBot, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mint, "~> 1.0"},
      {:mint_web_socket, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false}
    ]
  end
end

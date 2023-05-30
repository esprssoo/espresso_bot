defmodule EspressoBot.Discord.Shard.Supervisor do
  @moduledoc """
  Supervises Discord shards (websocket connections)
  """
  alias EspressoBot.Discord.Api
  alias EspressoBot.Discord.WebsocketClient

  use Supervisor

  def start_link(_) do
    {url, shards} = Api.gateway()

    Supervisor.start_link(__MODULE__, [url, shards], name: __MODULE__)
  end

  @impl true
  def init([url, shards]) do
    children = for num <- 1..shards, do: create_worker(url, num)

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 3)
  end

  def create_worker(gateway, num) do
    %{
      start: {WebsocketClient, :connect, [gateway]},
      id: num
    }
  end
end

defmodule EspressoBot.Discord.Shard.Supervisor do
  @moduledoc """
  Supervises Discord shards (websocket connections)
  """
  use Supervisor

  alias EspressoBot.Discord.Api
  alias EspressoBot.Discord.Shard

  def start_link(_) do
    {url, shards} = Api.gateway()

    Supervisor.start_link(__MODULE__, [url, shards], name: __MODULE__)
  end

  @impl true
  def init([url, shards]) do
    children = for num <- 1..shards, do: create_worker(url, num - 1, shards)

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 3)
  end

  def create_worker(gateway, num, total) do
    Supervisor.child_spec(
      {Shard, [gateway, num, total]},
      id: num
    )
  end
end

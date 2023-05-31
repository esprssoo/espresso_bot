defmodule EspressoBot do
  @moduledoc """
  THE Espresso bot
  """
  alias EspressoBot.Discord.Shard

  use Application

  def start(_type, []) do
    children = [
      Shard.Supervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

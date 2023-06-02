defmodule EspressoBot do
  @moduledoc """
  THE Espresso bot
  """
  alias EspressoBot.Discord.Data.ApplicationCommand
  alias EspressoBot.Discord.Api
  alias EspressoBot.Discord.Shard

  use Application

  def start(_type, []) do
    define_application_commands()

    children = [
      Shard.Supervisor,
      {Task.Supervisor, name: :event_handler}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def define_application_commands() do
    commands = [
      %ApplicationCommand{
        name: "echo",
        description: "Ηχός",
        type: 1,
        options: [
          %{name: "μήνυμα", description: "το μήνυμα", type: 3, required: true}
        ]
      }
    ]

    :ok = Api.bulk_overwrite_global_application_commands("442632725954953218", commands)
  end
end

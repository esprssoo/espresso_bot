defmodule EspressoBot.Handler do
  alias EspressoBot.Discord.Data.Interaction
  alias EspressoBot.Discord.Data.InteractionData
  alias EspressoBot.Discord.Api

  require Logger

  @spec dispatch(struct) :: :ok
  def dispatch(struct) do
    Task.Supervisor.async(:event_handler, fn -> handle(struct) end)
    :ok
  end

  defp handle(%Interaction{data: %InteractionData{name: "echo"} = data} = interaction) do
    echo = List.first(data.options)

    if echo != nil do
      Api.create_interaction_response(interaction, %{
        "type" => 4,
        "data" => %{"content" => "#{echo.value}"}
      })
    end
  end

  defp handle(data) do
    Logger.info("Received unhandled event\n-- #{inspect(data)}")
    :ok
  end
end

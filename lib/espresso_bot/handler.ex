defmodule EspressoBot.Handler do
  alias EspressoBot.Discord.Data.Interaction
  alias EspressoBot.Discord.Api

  require Logger

  @spec dispatch(struct) :: :ok
  def dispatch(struct) do
    Task.Supervisor.async(:event_handler, fn -> handle(struct) end)
    :ok
  end

  defp handle(%Interaction{} = data) do
    Api.create_interaction_response(data.id, data.token, %{
      "type" => 4,
      "data" => %{"content" => "You said: #{data.message}"}
    })
  end

  defp handle(data) do
    Logger.info("Received unhandled event\n-- #{inspect(data)}")
    :ok
  end
end

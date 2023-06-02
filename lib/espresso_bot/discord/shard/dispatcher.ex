defmodule EspressoBot.Discord.Shard.Dispatcher do
  alias EspressoBot.Discord.Data.Interaction
  alias EspressoBot.Handler

  require Logger

  def dispatch(payload) do
    {payload["t"], payload["d"]}
    |> format_event()
    |> Handler.dispatch()
  end

  defp format_event({"INTERACTION_CREATE", data}) do
    EspressoBot.Util.map_to_struct(data, %Interaction{})
  end

  # TODO: Handle all events
  defp format_event({_, data}), do: data
end

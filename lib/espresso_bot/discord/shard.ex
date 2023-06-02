defmodule EspressoBot.Discord.Shard do
  @moduledoc """
  Handles Discord gateway events and dispatches any unhandled events to a
  separate process.
  """

  alias EspressoBot.Client.WebsocketClient
  alias EspressoBot.Discord.Shard.Dispatcher
  alias EspressoBot.Discord.Shard.Payload

  require Logger

  use GenServer

  def start_link([gateway, shard_num, total_shards]) do
    GenServer.start_link(__MODULE__, [gateway, shard_num, total_shards])
  end

  @impl true
  def init(args) do
    {:ok, nil, {:continue, args}}
  end

  @impl true
  def handle_continue([gateway, shard_num, total_shards], nil) do
    {:ok, pid} = WebsocketClient.connect(gateway, self())

    state = %{
      websocket_pid: pid,
      shard_num: shard_num,
      total_shards: total_shards,
      seq: nil,
      heartbeat_ack: true,
      heartbeat_interval: nil,
      session_id: nil
    }

    Logger.debug("Websocket connection up on worker #{inspect(pid)}")

    {:noreply, state}
  end

  @impl true
  def handle_info({:event, text}, state) do
    payload = Jason.decode!(text)

    state = %{state | seq: payload["s"] || state.seq}

    handle =
      payload["op"]
      |> Payload.opcode_to_atom()
      |> handle_event(payload, state)

    case handle do
      {state, reply} ->
        Logger.debug("sending message:\n  #{inspect(reply)}")
        :ok = WebsocketClient.send_message(state.websocket_pid, reply)
        {:noreply, state}

      state ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:close, state) do
    Logger.debug("received close from WebsocketClient")
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    state = %{state | heartbeat_ack: false}

    # Apply timer for later
    Process.send_after(self(), :heartbeat, state.heartbeat_interval)

    # Also send heartbeat now
    :ok = WebsocketClient.send_message(state.websocket_pid, Payload.heartbeat(state.seq))

    {:noreply, state}
  end

  @impl true
  def handle_info(_message, state), do: {:noreply, state}

  defp handle_event(:hello, payload, state) do
    Logger.debug("HELLO")

    state = %{state | heartbeat_interval: payload["d"]["heartbeat_interval"]}
    Process.send_after(self(), :heartbeat, state.heartbeat_interval)

    if state.session_id == nil do
      Logger.info("IDENTIFY")
      {state, Payload.identify(state.shard_num, state.total_shards)}
    else
      Logger.info("RESUME")
      {state, Payload.resume(state.seq, state.session_id)}
    end
  end

  defp handle_event(:heartbeat, _payload, state) do
    Logger.debug("HEARTBEAT PING")

    {state, Payload.heartbeat(state.seq)}
  end

  defp handle_event(:heartbeat_ack, _payload, state) do
    Logger.debug("HEARTBEAT ACK")

    %{state | heartbeat_ack: true}
  end

  defp handle_event(:dispatch, payload, state) do
    Logger.debug("DISPATCH")

    :ok = Dispatcher.dispatch(payload)

    if payload["t"] == "READY" do
      Logger.info("READY")
      %{state | session_id: payload["d"]["session_id"]}
    else
      state
    end
  end

  defp handle_event(:reconnect, _payload, state) do
    Logger.debug("RECONNECT")

    state
  end

  defp handle_event(:invalid_session, _payload, state) do
    Logger.debug("INVALID_SESSION")

    {state, Payload.identify(state.shard_num, state.total_shards)}
  end
end

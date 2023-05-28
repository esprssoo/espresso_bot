defmodule EspressoBot.Discord.WebsocketClient do
  @moduledoc false

  defstruct [
    :conn,
    :websocket,
    requests: %{}
  ]

  alias EspressoBot.Discord.HttpClient
  alias EspressoBot.Discord.BaseClient, as: Base

  require HttpClient

  use Base, [:websocket]

  @type t :: %__MODULE__{conn: Mint.HTTP.t()}

  @impl true
  def handle_connect(domain, from, state) do
    path = "/?v=10&encoding=json"
    opts = Base.connect_opts() ++ [protocols: [:http1]]

    with {:ok, conn} <- Mint.HTTP.connect(:https, domain, 443, opts),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(:wss, conn, path, []) do
      state = %__MODULE__{
        state
        | conn: conn,
          requests: %{ref => %{from: from, response: HttpClient.response()}}
      }

      {:noreply, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
      {:error, conn, reason} -> {:reply, {:error, reason}, put_in(state.conn, conn)}
    end
  end

  @impl true
  def handle_responses({:done, ref}, state) do
    HttpClient.response(status: status, headers: headers) = state.requests[ref].response

    case Mint.WebSocket.new(state.conn, ref, status, headers) do
      {:ok, conn, websocket} ->
        GenServer.reply(state.requests[ref].from, :ok)
        %__MODULE__{state | conn: conn, websocket: websocket}

      {:error, websocket, reason} ->
        GenServer.reply(state.requests[ref].from, {:error, reason})
        %__MODULE__{state | websocket: websocket}
    end
  end

  @impl true
  def handle_responses({:data, ref, data}, %__MODULE__{websocket: websocket} = state)
      when websocket != nil do
    case Mint.WebSocket.decode(websocket, data) do
      {:ok, websocket, frames} ->
        put_in(state.websocket, websocket)
        |> handle_frames(frames)

      {:error, websocket, reason} ->
        GenServer.reply(state.requests[ref].from, {:error, reason})
        put_in(state.websocket, websocket)
    end
  end

  defp handle_frames(state, frames) do
    IO.inspect(frames)

    state
  end
end

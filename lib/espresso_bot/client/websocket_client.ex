defmodule EspressoBot.Client.WebsocketClient do
  @moduledoc false

  defstruct [
    :conn,
    :websocket,
    :request_ref,
    :caller,
    :sender,
    requests: %{},
    closing?: false
  ]

  alias EspressoBot.Client.HttpClient
  alias EspressoBot.Client.BaseClient, as: Base

  require HttpClient

  use Base, [:websocket]

  # @type t :: %__MODULE__{conn: Mint.HTTP.t()}

  @doc """
  Connect to a websocket on `domain`
  """
  @spec connect(String.t(), pid) :: {:ok, pid} | {:error, term}
  def connect(domain, sender) do
    with {:ok, pid} <- GenServer.start_link(__MODULE__, []),
         :ok <- GenServer.call(pid, {:connect, domain, sender}) do
      {:ok, pid}
    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Sends a message to the websocket. `msg` must be serialized before sending.
  """
  @spec send_message(pid, String.t()) :: :ok | {:error, term}
  def send_message(pid, msg) do
    GenServer.call(pid, {:send, msg})
  end

  @impl true
  def handle_call({:connect, domain, sender}, from, state) do
    path = "/?v=10&encoding=json"
    opts = Base.connect_opts() ++ [protocols: [:http1]]

    with {:ok, conn} <- Mint.HTTP.connect(:https, domain, 443, opts),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(:wss, conn, path, []) do
      state = %__MODULE__{
        state
        | conn: conn,
          request_ref: ref,
          caller: from,
          sender: sender,
          requests: %{ref => %{from: from, response: HttpClient.response()}}
      }

      {:noreply, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
      {:error, conn, reason} -> {:reply, {:error, reason}, put_in(state.conn, conn)}
    end
  end

  @impl true
  def handle_call({:send, msg}, _from, state) do
    case stream_frame(state, {:text, msg}) do
      {:ok, state} -> {:reply, :ok, state}
      {:error, state, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_info(message, %__MODULE__{} = state) do
    case Mint.WebSocket.stream(state.conn, message) do
      :unknown ->
        Logger.debug("[websocket] got unknown message: " <> message)

        {:noreply, state}

      {:ok, conn, responses} ->
        state = %__MODULE__{state | conn: conn}
        state = Enum.reduce(responses, state, &handle_responses/2)

        if state.closing?, do: do_close(state), else: {:noreply, state}

      {:error, _conn, reason, _responses} ->
        raise reason
    end
  end

  @impl true
  def handle_responses({:done, ref}, state) do
    HttpClient.response(status: status, headers: headers) = state.requests[ref].response

    case Mint.WebSocket.new(state.conn, ref, status, headers) do
      {:ok, conn, websocket} ->
        state = %__MODULE__{state | conn: conn, websocket: websocket}
        GenServer.reply(state.caller, :ok)

        state

      {:error, websocket, reason} ->
        state = %__MODULE__{state | websocket: websocket}
        GenServer.reply(state.caller, {:error, reason})

        state
    end
  end

  @impl true
  def handle_responses({:data, _ref, data}, %__MODULE__{websocket: websocket} = state)
      when websocket != nil do
    case Mint.WebSocket.decode(websocket, data) do
      {:ok, websocket, frames} ->
        put_in(state.websocket, websocket)
        |> handle_frames(frames)

      {:error, websocket, reason} ->
        GenServer.reply(state.caller, {:error, reason})
        put_in(state.websocket, websocket)
    end
  end

  defp handle_frames(state, [frame | rest]) do
    state =
      case frame do
        {:text, text} ->
          send(state.sender, {:event, text})

          state

        {:binary, _binary} ->
          Logger.warn("[websocket] Not handling binary frames!")

          state

        {:ping, binary} ->
          Logger.debug("[websocket] ping!")
          {:ok, state} = stream_frame(state, {:pong, binary})

          state

        {:pong, _binary} ->
          Logger.warn("[websocket] Not handling pong frames!")

          state

        {:close, _code, reason} ->
          Logger.debug("[websocket] received a close: #{inspect(reason)}")
          state = put_in(state.closing?, true)

          state
      end

    state
    |> handle_frames(rest)
  end

  defp handle_frames(state, []), do: state

  defp stream_frame(state, frame) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(state.websocket, frame),
         state = put_in(state.websocket, websocket),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(state.conn, state.request_ref, data) do
      {:ok, put_in(state.conn, conn)}
    else
      {:error, %Mint.WebSocket{} = websocket, error} ->
        {:error, put_in(state.websocket, websocket), error}

      {:error, conn, error} ->
        {:error, put_in(state.conn, conn), error}
    end
  end

  defp do_close(state) do
    _ = stream_frame(state, :close)
    Mint.HTTP.close(state.conn)
    send(state.sender, :close)
    {:stop, :normal, state}
  end
end

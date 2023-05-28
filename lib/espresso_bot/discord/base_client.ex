defmodule EspressoBot.Discord.BaseClient do
  @moduledoc false

  alias EspressoBot.Discord.BaseClient
  alias EspressoBot.Discord.HttpClient

  @callback handle_responses(Mint.Types.response(), term) :: term
  @callback handle_connect(String.t(), reference, term) :: term

  defmacro __using__(opts) do
    module =
      if Enum.member?(opts, :websocket) do
        Mint.WebSocket
      else
        Mint.HTTP
      end

    quote do
      @behaviour BaseClient
      @before_compile BaseClient

      use GenServer

      require Logger

      @spec connect(String.t()) :: {:ok, pid} | {:error, term}
      def connect(domain) do
        with {:ok, pid} <- GenServer.start_link(__MODULE__, []),
             :ok <- GenServer.call(pid, {:connect, domain}) do
          {:ok, pid}
        else
          {:error, error} -> {:error, error}
        end
      end

      @impl true
      def init([]) do
        {:ok, %__MODULE__{}}
      end

      @impl true
      def handle_call({:connect, domain}, from, state) do
        handle_connect(domain, from, state)
      end

      @impl true
      def handle_info(message, %__MODULE__{} = state) do
        case unquote(module).stream(state.conn, message) do
          :unknown ->
            Logger.debug("Got unknown message: " <> message)

            {:noreply, state}

          {:ok, conn, responses} ->
            state = %__MODULE__{state | conn: conn}
            state = Enum.reduce(responses, state, &handle_responses/2)

            {:noreply, state}

          {:error, conn, reason, responses} ->
            raise reason
        end
      end

      def handle_connect(domain, from, state)

      defoverridable BaseClient
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def handle_responses(state, responses), do: HttpClient.handle_responses(state, responses)
    end
  end

  def connect_opts, do: [transport_opts: [cacerts: :public_key.cacerts_get()]]
end

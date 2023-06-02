defmodule EspressoBot.Client.BaseClient do
  @moduledoc false

  alias EspressoBot.Client.BaseClient
  alias EspressoBot.Client.HttpClient

  @callback handle_response(Mint.Types.response(), term) :: term
  @callback do_close(term) :: term

  defmacro __using__(_) do
    quote do
      @behaviour BaseClient
      @before_compile BaseClient

      use GenServer

      @impl true
      def init(_) do
        {:ok, %__MODULE__{}}
      end

      @impl true
      def handle_cast(:close, state) do
        do_close(state)
      end

      @impl true
      def terminate(_reason, state) do
        Mint.HTTP.close(state.conn)
      end

      defoverridable BaseClient
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def close(pid), do: GenServer.cast(pid, :close)

      def handle_response(responses, state), do: HttpClient.handle_response(responses, state)
    end
  end

  def connect_opts, do: [transport_opts: [cacerts: :public_key.cacerts_get()]]
end

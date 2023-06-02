defmodule EspressoBot.Client.BaseClient do
  @moduledoc false

  alias EspressoBot.Client.BaseClient
  alias EspressoBot.Client.HttpClient

  @callback handle_responses(Mint.Types.response(), term) :: term

  defmacro __using__(_) do
    quote do
      @behaviour BaseClient
      @before_compile BaseClient

      use GenServer

      require Logger

      @impl true
      def init(_) do
        {:ok, %__MODULE__{}}
      end

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

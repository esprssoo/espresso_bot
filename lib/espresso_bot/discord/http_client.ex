defmodule EspressoBot.Discord.HttpClient do
  @moduledoc false

  defstruct [
    :conn,
    requests: %{}
  ]

  alias EspressoBot.Discord.BaseClient, as: Base

  use Base
  import Record

  defrecord :response, status: nil, headers: [], data: ""

  @type t :: %__MODULE__{
          conn: Mint.HTTP.t(),
          requests: %{
            Mint.Types.request_ref() => %{
              from: reference,
              responses: {integer, [header], String.t()}
            }
          }
        }

  @type response :: record(:response, status: integer, headers: [header], data: String.t())
  @type header :: {String.t(), String.t()}

  @spec request(pid, method, String.t(), [header], String.t()) ::
          {:ok, response()} | {:error, term}
        when method: :get | :post | :put
  def request(pid, method, route, headers, data) do
    GenServer.call(pid, {:request, method, route, headers, data})
  end

  @impl true
  def handle_connect(domain, _from, state) do
    case Mint.HTTP.connect(:https, domain, 443, Base.connect_opts()) do
      {:ok, conn} ->
        state = %__MODULE__{state | conn: conn}
        {:reply, :ok, state}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:request, method, route, headers, body}, from, state) do
    method =
      method
      |> to_string()
      |> String.upcase()

    case Mint.HTTP.request(state.conn, method, route, headers, body) do
      {:ok, conn, ref} ->
        state = put_in(state.conn, conn)
        state = put_in(state.requests[ref], %{from: from, response: response()})

        {:noreply, state}

      {:error, conn, reason} ->
        state = put_in(state.conn, conn)

        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_responses({:status, ref, status}, state) do
    put_in(state.requests[ref].response, response(state.requests[ref].response, status: status))
  end

  @impl true
  def handle_responses({:headers, ref, headers}, state) do
    put_in(state.requests[ref].response, response(state.requests[ref].response, headers: headers))
  end

  @impl true
  def handle_responses({:data, ref, new_data}, state) do
    response = state.requests[ref].response
    data = response(response, :data)
    put_in(state.requests[ref].response, response(response, data: data <> new_data))
  end

  @impl true
  def handle_responses({:done, ref}, state) do
    {request, state} = pop_in(state.requests[ref])
    GenServer.reply(request.from, {:ok, request.response})
    state
  end
end

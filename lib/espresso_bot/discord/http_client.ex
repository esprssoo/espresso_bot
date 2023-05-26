defmodule EspressoBot.Discord.HttpClient do
  use GenServer

  require Logger

  defstruct [:conn, requests: %{}]

  @domain "discord.com"
  @base_route "/api/v10"

  @type headers :: [{String.t(), String.t()}]
  @type body :: binary | String.t()
  @type response :: {integer, headers, body}

  def open do
    GenServer.start_link(__MODULE__, [])
  end

  @spec request(pid, method, route, headers, body) :: {:ok, response} | {:error, term}
        when route: String.t(),
             method: :get | :post | :put
  def request(pid, method, route, headers, body \\ "") do
    GenServer.call(pid, {:request, method, route, headers, body})
  end

  @impl true
  def init([]) do
    opts = [transport_opts: [cacerts: :public_key.cacerts_get()]]

    case Mint.HTTP.connect(:https, @domain, 443, opts) do
      {:ok, conn} -> {:ok, %__MODULE__{conn: conn, requests: %{}}}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:request, method, route, headers, body}, from, %__MODULE__{} = state) do
    route = @base_route <> route

    method =
      method
      |> to_string()
      |> String.upcase()

    case Mint.HTTP.request(state.conn, method, route, headers, body) do
      {:ok, conn, req_ref} ->
        state = %__MODULE__{
          state
          | conn: conn,
            requests: put_in(state.requests, [req_ref], %{from: from, response: {nil, nil, nil}})
        }

        {:noreply, state}

      {:error, conn, reason} ->
        state = %__MODULE__{state | conn: conn}
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(message, %__MODULE__{} = state) do
    case Mint.HTTP.stream(state.conn, message) do
      :unknown ->
        handle_unknown_message(message)
        {:noreply, state}

      {:error, conn, reason, responses} ->
        handle_error(reason, responses)
        {:noreply, %__MODULE__{state | conn: conn}}

      {:ok, conn, responses} ->
        requests = Enum.reduce(responses, state.requests, &handle_responses/2)
        state = %__MODULE__{state | conn: conn, requests: requests}
        {:noreply, state}
    end
  end

  @impl true
  def terminate(:normal, %__MODULE__{} = state) do
    Mint.HTTP.close(state.conn)
  end

  defp handle_responses({:status, req_ref, status}, requests) do
    update_in(requests[req_ref][:response], fn {_, headers, data} -> {status, headers, data} end)
  end

  defp handle_responses({:headers, req_ref, headers}, requests) do
    update_in(requests[req_ref][:response], fn {status, _, data} -> {status, headers, data} end)
  end

  defp handle_responses({:data, req_ref, new_data}, requests) do
    update_in(requests[req_ref][:response], fn {status, headers, data} ->
      {status, headers, data || "" <> new_data}
    end)
  end

  defp handle_responses({:done, req_ref}, requests) do
    {request, requests} = pop_in(requests[req_ref])
    GenServer.reply(request.from, {:ok, request.response})
    requests
  end

  defp handle_responses({:error, req_ref, reason}, requests) do
    {request, requests} = pop_in(requests[req_ref])
    GenServer.reply(request.from, {:error, reason})
    requests
  end

  defp handle_unknown_message(message) do
    Logger.warn("Received unknown message: " <> message)
  end

  defp handle_error(error, _responses) do
    # TODO: Handle error?
    raise error
  end
end

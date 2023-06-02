defmodule EspressoBot.Discord.Api do
  @moduledoc """
  Module to interact with the Discord API.
  """

  @base_route "/api/v10"

  alias EspressoBot.Client.HttpClient
  alias EspressoBot.Client.Request

  require HttpClient

  def create_interaction_response(id, token, options) do
    route = "/interactions/#{id}/#{token}/callback"

    request(:post, route, options)
    |> authorized()
  end

  def bulk_overwrite_global_application_commands(application_id, commands) do
    request(:put, "/applications/#{application_id}/commands", commands)
    |> authorized()
  end

  @spec gateway() :: {String.t(), integer}
  def gateway() do
    case :persistent_term.get(:discord_gateway_url, nil) do
      nil -> get_new_gateway_url()
      result -> result
    end
  end

  defp get_new_gateway_url() do
    case request(:get, "/gateway/bot", "") |> authorized() do
      {:ok, body} ->
        "wss://" <> url = body["url"]
        shards = if body["shards"], do: body["shards"], else: 1

        :persistent_term.put(:discord_gateway_url, {url, shards})

        {url, shards}

      {:error, error} ->
        raise error
    end
  end

  defp request(method, route, body, headers \\ []) do
    {:ok, conn} = HttpClient.connect("discord.com")

    %Request{
      conn: conn,
      method: method,
      route: @base_route <> route,
      body: body,
      headers: headers
    }
  end

  defp authorized(%Request{} = request) do
    bot_token_header =
      {"authorization", "Bot #{Application.get_env(:espresso_bot, :discord_bot_token)}"}

    request = %Request{request | headers: [bot_token_header | request.headers]}
    response = do_request(request)
    HttpClient.close(request.conn)

    response
  end

  defp do_request(%Request{} = request) do
    headers = [{"content-type", "application/json"} | request.headers]

    HttpClient.request(
      request.conn,
      request.method,
      request.route,
      headers,
      process_request_body(request.body)
    )
    |> format_response()
    |> decode_response()
  end

  defp format_response(response) do
    case response do
      {:error, error} ->
        {:error, error}

      {:ok, HttpClient.response(status: status, data: data)} when status in [200, 201] ->
        {:ok, data}

      {:ok, HttpClient.response(status: 204)} ->
        {:ok}

      {:ok, HttpClient.response(status: status, data: data)} ->
        {:error, %{status_code: status, error: data}}
    end
  end

  defp decode_response({:error, _} = response), do: response
  defp decode_response({:ok}), do: {:ok}

  defp decode_response({:ok, data}) do
    convert = data |> Jason.decode!()
    {:ok, convert}
  end

  defp process_request_body(""), do: ""
  defp process_request_body(body), do: Jason.encode_to_iodata!(body)
end

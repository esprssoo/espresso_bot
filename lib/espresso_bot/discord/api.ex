defmodule EspressoBot.Discord.Api do
  @moduledoc """
  Module to interact with the Discord API.
  """

  alias EspressoBot.Discord.HttpClient

  require HttpClient

  @spec gateway() :: String.t()
  def gateway() do
    case :persistent_term.get(:discord_gateway_url, nil) do
      nil -> get_new_gateway_url()
      url -> url
    end
  end

  defp get_new_gateway_url() do
    bot_token_header =
      {"authorization", "Bot #{Application.get_env(:espresso_bot, :discord_bot_token)}"}

    url =
      case do_request(:get, "/api/v10/gateway/bot", [bot_token_header]) do
        {:ok, body} -> body["url"]
        {:error, error} -> raise error
      end

    :persistent_term.put(:discord_gateway_url, url)
    url
  end

  defp do_request(method, route, headers) do
    {:ok, conn} = HttpClient.connect("discord.com")
    headers = [{"content-type", "application/json"}] ++ headers

    HttpClient.request(conn, method, route, headers, "")
    |> format_response()
    |> decode_response()
  end

  defp format_response(response) do
    case response do
      {:error, error} ->
        {:error, error}

      {:ok, HttpClient.response(status: status, data: data)} when status in [200, 201] ->
        {:ok, data}

      {:ok, HttpClient.response(status: status, data: data)} ->
        {:error, %{status_code: status, error: Jason.decode!(data, keys: :atoms)}}
    end
  end

  defp decode_response({:error, _} = response), do: response

  defp decode_response({:ok, data}) do
    convert = data |> Jason.decode!()
    {:ok, convert}
  end
end

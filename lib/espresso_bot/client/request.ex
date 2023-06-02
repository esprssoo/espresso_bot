defmodule EspressoBot.Client.Request do
  defstruct [
    :conn,
    :method,
    :route,
    :headers,
    :body
  ]
end

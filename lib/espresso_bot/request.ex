defmodule EspressoBot.Request do
  defstruct [
    :conn,
    :method,
    :route,
    :headers,
    :body
  ]
end

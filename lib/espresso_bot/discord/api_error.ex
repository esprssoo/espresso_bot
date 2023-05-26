defmodule EspressoBot.Discord.ApiError do
  defexception [:status_code, :error]

  @type t :: %{
          status_code: status_code,
          response: response
        }

  @type status_code :: 100..511
  @type special_status_code :: integer

  @type response :: String.t() | error

  @type error :: %{code: special_status_code, message: String.t()}

  @impl true
  def message(%__MODULE__{error: error, status_code: status}) do
    "(HTTP #{status}) received a Discord error #{error.code} #{error.message}"
  end
end

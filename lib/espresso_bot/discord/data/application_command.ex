defmodule EspressoBot.Discord.Data.ApplicationCommand do
  @moduledoc """
  An application command object

  Reference:
  [](https://discord.com/developers/docs/interactions/application-commands)

  ## Fields

  - name: The name
  - description: The description. Must be empty for `USER` and `MESSAGE` commands
  - type: the command type (see `command_type`)
  - options: the command options (see `command_option`)
  """

  @enforce_keys [:name, :description]

  @derive {Jason.Encoder, []}
  defstruct [
    :name,
    :description,
    :type,
    options: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          type: command_type(),
          options: [command_option()]
        }

  @typedoc """
  - `1` for CHAT_INPUT
  - `2` for USER
  - `3` for MESSAGE
  """
  @type command_type :: pos_integer

  @typedoc """
  Only valid for `CHAT_INPUT` commands (see `command_type`)
  """
  @type command_option :: %{
          required(:name) => String.t(),
          required(:description) => String.t(),
          required(:type) => pos_integer,
          optional(:required) => boolean(),
          optional(:choices) => [command_choice()],
          optional(:options) => [command_option()],
          optional(:autocomplete) => boolean()
          # optional(:channel_types) =>
        }

  @type command_choice :: %{
          name: String.t(),
          value: String.t()
        }
end

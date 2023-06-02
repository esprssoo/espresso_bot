defmodule EspressoBot.Discord.Data.InteractionData do
  alias EspressoBot.Discord.Data.InteractionDataOption

  defstruct [
    :id,
    :name,
    :resolved,
    :options,
    :custom_id,
    :component_type,
    :type,
    :values,
    :target_id,
    :components
  ]

  @spec to_struct(map) :: %__MODULE__{}
  def to_struct(map) do
    EspressoBot.Util.cast_to_struct(map, __MODULE__, options: InteractionDataOption)
  end
end

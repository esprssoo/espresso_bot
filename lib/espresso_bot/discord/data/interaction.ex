defmodule EspressoBot.Discord.Data.Interaction do
  alias EspressoBot.Discord.Data.InteractionData

  defstruct [
    :id,
    :application_id,
    :type,
    :data,
    :guild_id,
    :channel,
    :channel_id,
    :member,
    :user,
    :token,
    :version,
    :message,
    :app_permissions,
    :locale,
    :guild_locale
  ]

  @spec to_struct(map) :: %__MODULE__{}
  def to_struct(map) do
    EspressoBot.Util.cast_to_struct(map, __MODULE__, data: InteractionData)
  end
end

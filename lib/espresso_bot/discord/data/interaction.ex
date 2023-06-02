defmodule EspressoBot.Discord.Data.Interaction do
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
end

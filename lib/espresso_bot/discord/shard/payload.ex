defmodule EspressoBot.Discord.Shard.Payload do
  import Bitwise

  @spec opcode_to_atom(integer) :: atom
  def opcode_to_atom(0), do: :dispatch
  def opcode_to_atom(1), do: :heartbeat
  def opcode_to_atom(7), do: :reconnect
  def opcode_to_atom(9), do: :invalid_session
  def opcode_to_atom(10), do: :hello
  def opcode_to_atom(11), do: :heartbeat_ack
  def opcode_to_atom(op), do: raise("RECEIVE OPCODE #{op} NOT IMPLEMENTED")

  @spec heartbeat(integer) :: String.t()
  def heartbeat(sequence) do
    sequence
    |> build(1)
  end

  @spec identify(integer, integer) :: String.t()
  def identify(shard_num, total_shards) do
    {os, name} = :os.type()

    %{
      "token" => Application.get_env(:espresso_bot, :discord_bot_token),
      "properties" => %{
        "os" => "#{Atom.to_string(os)} #{Atom.to_string(name)}",
        "browser" => "EspressoBot",
        "device" => "EspressoBot"
      },
      "compress" => false,
      "shard" => [shard_num, total_shards],
      "intents" => 1 <<< 9
    }
    |> build(2)
  end

  @spec resume(integer, String.t()) :: String.t()
  def resume(seq, session_id) do
    %{
      "token" => Application.get_env(:espresso_bot, :discord_bot_token),
      "session_id" => session_id,
      "seq" => seq
    }
    |> build(6)
  end

  defp build(data, opcode) do
    %{"op" => opcode, "d" => data}
    |> Jason.encode!()
  end
end

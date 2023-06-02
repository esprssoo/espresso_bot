defmodule EspressoBot.Util do
  @spec map_to_struct(map, struct) :: struct
  def map_to_struct(map, struct) do
    string_keys = struct |> Map.keys() |> Enum.map(&Atom.to_string/1)

    Enum.reduce(map, struct, fn
      {k, v}, acc ->
        if Enum.member?(string_keys, k),
          do: %{acc | String.to_existing_atom(k) => v},
          else: acc
    end)
  end
end

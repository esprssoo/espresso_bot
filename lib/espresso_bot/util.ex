defmodule EspressoBot.Util do
  @spec cast_to_struct(map, module, keyword(module())) :: struct
  def cast_to_struct(map, struct_module, inner_struct_modules) do
    Enum.reduce(
      map,
      struct(struct_module, %{}),
      &cast(&1, &2, struct_module, inner_struct_modules)
    )
  end

  defp cast({_, val}, acc, _, _) when is_nil(val) do
    acc
  end

  defp cast({key, val}, acc, _, inner_struct_modules) when is_map(val) do
    key = String.to_existing_atom(key)
    struct_module = Keyword.get(inner_struct_modules, key)

    if struct_module == nil do
      acc
    else
      val =
        if function_exported?(struct_module, :to_struct, 1),
          do: struct_module.to_struct(val),
          else: cast_to_struct(val, struct_module, inner_struct_modules)

      %{acc | key => val}
    end
  rescue
    ArgumentError -> acc
  end

  defp cast({key, val}, acc, _, inner_struct_modules) when is_list(val) do
    key = String.to_existing_atom(key)
    struct_module = Keyword.get(inner_struct_modules, key)

    if struct_module == nil do
      acc
    else
      val =
        if function_exported?(struct_module, :to_struct, 1),
          do: Enum.reduce(val, [], fn elem, acc -> [struct_module.to_struct(elem) | acc] end),
          else:
            Enum.reduce(val, [], fn elem, acc ->
              [cast_to_struct(elem, struct_module, inner_struct_modules) | acc]
            end)

      %{acc | key => val}
    end
  rescue
    ArgumentError -> acc
  end

  defp cast({key, val}, acc, struct_module, _inner_structs) do
    string_keys = struct(struct_module) |> Map.keys() |> Enum.map(&Atom.to_string/1)

    if Enum.member?(string_keys, key) do
      %{acc | String.to_existing_atom(key) => val}
    else
      acc
    end
  end

  defp cast(element, _acc, _struct, _inner_structs) do
    element
  end
end

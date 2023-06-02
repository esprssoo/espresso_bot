defmodule EspressoBotTest do
  alias EspressoBot.Discord.Data.Interaction

  use ExUnit.Case
  doctest EspressoBot

  test "map to struct" do
    map = %{"id" => 1, "foo" => "asdsad"}

    the_struct = Interaction.to_struct(map)
    assert ^the_struct = %Interaction{:id => 1}
  end
end

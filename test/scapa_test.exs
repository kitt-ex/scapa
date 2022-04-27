defmodule ScapaTest do
  use ExUnit.Case
  doctest Scapa

  test "greets the world" do
    assert Scapa.hello() == :world
  end
end

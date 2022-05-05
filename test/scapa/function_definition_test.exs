defmodule Scapa.FunctionDefinitionTest do
  use ExUnit.Case, async: true
  doctest Scapa.FunctionDefinition

  alias Scapa.FunctionDefinition

  describe "line_number/1" do
    test "returns the correct line number" do
      assert 42 = FunctionDefinition.line_number(%FunctionDefinition{position: {42, 8}})
    end
  end
end

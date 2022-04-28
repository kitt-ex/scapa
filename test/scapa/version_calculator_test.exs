defmodule Scapa.VersionCalculatorTest do
  use ExUnit.Case, async: true
  doctest Scapa.VersionCalculator

  alias Scapa.FunctionDefinition
  alias Scapa.VersionCalculator

  describe "calculate/1" do
    test "returns the same version for the same function signature" do
      signature_a = {__MODULE__, :hello, 2, "hello(arg1, arg2)"}
      signature_b = {__MODULE__, :hello, 2, "hello(arg1, arg2)"}

      assert VersionCalculator.calculate(%FunctionDefinition{signature: signature_a}) ==
               VersionCalculator.calculate(%FunctionDefinition{signature: signature_b})
    end

    test "returns a different version when the function signature changes" do
      signature_a = {__MODULE__, :hello, 1, "hello(arg1)"}
      signature_b = {__MODULE__, :hello, 2, "hello(arg1, arg2)"}

      assert VersionCalculator.calculate(%FunctionDefinition{signature: signature_a}) !=
               VersionCalculator.calculate(%FunctionDefinition{signature: signature_b})
    end
  end
end

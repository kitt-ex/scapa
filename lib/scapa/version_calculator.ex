defmodule Scapa.VersionCalculator do
  @moduledoc false
  alias Scapa.FunctionDefinition

  @type version() :: String.t()

  @doc """
  Calculates the version of a function definition based on it's signature.

  ## Examples

    iex> Scapa.VersionCalculator.calculate(%Scapa.FunctionDefinition{signature: {Scapa.VersionCalculator, :hello, 1, "hello(arg1)"}})
    "47674823"
  """
  @spec calculate(FunctionDefinition.t()) :: version()
  @doc version: "98757687"
  def calculate(%FunctionDefinition{signature: signature}) do
    Integer.to_string(:erlang.phash2(signature))
  end
end

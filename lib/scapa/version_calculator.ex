defmodule Scapa.VersionCalculator do
  @moduledoc false
  alias Scapa.FunctionDefinition

  @type version() :: String.t()

  @doc """
  Calculates the version of a function definition based on it's signature.

  ## Examples

    iex> Scapa.VersionCalculator.calculate(%Scapa.FunctionDefinition{signature: {Scapa.VersionCalculator, :hello, 1, "hello(arg1)"}})
    "NDc2NzQ4MjM"
  """
  @spec calculate(FunctionDefinition.t()) :: version()
  @doc version: "OTg3NTc2ODc"
  def calculate(%FunctionDefinition{signature: signature}) do
    signature
    |> :erlang.phash2()
    |> Integer.to_string()
    |> Base.encode64(padding: false)
  end
end

defmodule Scapa.VersionCalculator do
  @moduledoc false
  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile

  @type version() :: String.t()

  @doc """
  Calculates the version of all function definitions based on their signature.

  ## Examples

    iex> Scapa.VersionCalculator.calculate(%Scapa.SourceFile{documented_functions: [%Scapa.FunctionDefinition{signature: {Scapa.VersionCalculator, :hello, 1, "hello(arg1)"}}]})
    %{{Scapa.VersionCalculator, :hello, 1, "hello(arg1)"} => "NDc2NzQ4MjM"}
  """
  @spec calculate(SourceFile.t()) :: %{FunctionDefinition.signature() => version()}
  def calculate(%SourceFile{documented_functions: functions}) do
    functions
    |> Enum.reduce(%{}, fn %FunctionDefinition{signature: signature} = function_definition,
                           versions ->
      Map.put(versions, signature, hash_version(function_definition))
    end)
  end

  defp hash_version(%FunctionDefinition{signature: signature}) do
    signature
    |> :erlang.phash2()
    |> Integer.to_string()
    |> Base.encode64(padding: false)
  end
end

defmodule Scapa.CLI do
  @moduledoc false

  alias Scapa.FunctionDefinition
  alias Scapa.VersionCalculator

  @doc """
  Receives a pattern for files to look into and generates versions for those
  """
  def generate_versions(files_pattern \\ "lib/**/*.ex") do
    files_to_versionate(files_pattern)
    |> Enum.map(&{&1, add_versions_to_file(&1)})
    |> Enum.filter(&elem(&1, 1))
  end

  defp files_to_versionate(files_pattern) do
    files_pattern
    |> Path.wildcard()
    |> Enum.map(&Path.expand/1)
    |> MapSet.new()
  end

  defp add_versions_to_file(file_path) do
    file_content = File.read!(file_path)

    case funtions_to_versionate(file_content) do
      [] ->
        nil

      function_definitions ->
        Enum.reduce(function_definitions, file_content, fn function_definition, content ->
          Scapa.Code.upsert_doc_version(
            content,
            function_definition,
            VersionCalculator.calculate(function_definition)
          )
        end)
    end
  end

  defp funtions_to_versionate(file_contents) do
    file_contents
    |> Code.string_to_quoted!()
    |> Scapa.Code.defined_modules()
    |> Enum.flat_map(&Scapa.Code.functions_with_doc({:module, &1, file_contents}))
    |> Enum.sort_by(&FunctionDefinition.line_number/1)
    |> Enum.reverse()
  end
end

defmodule Scapa.CLI do
  @moduledoc false

  alias Scapa.FunctionDefinition
  alias Scapa.VersionCalculator

  @doc """
  Receives a pattern for files to look into and generates versions for those
  """
  @doc version: "124861924"
  def generate_versions(files_pattern) do
    files_to_versioning(files_pattern)
    |> Enum.map(&{&1, add_versions_to_file(&1)})
    |> Enum.filter(&elem(&1, 1))
  end

  defp files_to_versioning(files_pattern) do
    files_pattern
    |> Path.wildcard()
    |> Enum.map(&Path.expand/1)
    |> MapSet.new()
  end

  defp add_versions_to_file(file_path) do
    file_content = File.read!(file_path)

    case functions_to_version(file_content) do
      [] ->
        nil

      function_definitions ->
        case upsert_doc_in_file(function_definitions, file_content) do
          # If the file is already versioned, we don't need to do anything
          ^file_content -> nil
          # If the file is not versioned, we need to add the versioning
          result -> result
        end
    end
  end

  defp upsert_doc_in_file(function_definitions, file_content) do
    Enum.reduce(function_definitions, file_content, fn function_definition, content ->
      Scapa.Code.upsert_doc_version(
        content,
        function_definition,
        VersionCalculator.calculate(function_definition)
      )
    end)
  end

  defp functions_to_version(file_contents) do
    file_contents
    |> Code.string_to_quoted!()
    |> Scapa.Code.defined_modules()
    |> Enum.flat_map(&Scapa.Code.functions_with_doc({:module, &1, file_contents}))
    |> Enum.sort_by(&FunctionDefinition.line_number/1)
    |> Enum.reverse()
  end
end

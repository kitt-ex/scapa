defmodule Scapa.CLI do
  @moduledoc false

  alias Scapa.Config
  alias Scapa.FunctionDefinition
  alias Scapa.VersionCalculator

  @type result ::
          {:ok, content(), path()}
          | {:ok, :no_changes, path()}
          | {:error, formatted_error_message(), path()}
  @typep content :: String.t()
  @typep path :: String.t()
  @typep formatted_error_message :: String.t()

  @doc """
  Receives a pattern for files to look into and generates versions for those
  """
  @doc version: "34012995"
  @spec generate_versions(Config.t()) :: [result()]
  def generate_versions(%Config{include: files_patterns}) do
    files_to_version(files_patterns)
    |> Enum.map(&add_versions_to_file/1)
  end

  defp files_to_version(files_patterns) do
    files_patterns
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.map(&Path.expand/1)
    |> MapSet.new()
  end

  defp add_versions_to_file(file_path) do
    file_content = File.read!(file_path)
    function_definitions = functions_to_version(file_content, file_path)

    case upsert_docs_in_file(function_definitions, file_content) do
      ^file_content ->
        {:ok, :no_changes, file_path}

      new_content when is_binary(new_content) ->
        {:ok, new_content, file_path}
    end
  rescue
    e ->
      {:error, Exception.format(:error, e, Enum.slice(__STACKTRACE__, 0, 5)), file_path}
  end

  defp upsert_docs_in_file(function_definitions, file_content) do
    Enum.reduce(function_definitions, file_content, fn function_definition, content ->
      Scapa.Code.upsert_doc_version(
        content,
        function_definition,
        VersionCalculator.calculate(function_definition)
      )
    end)
  end

  defp functions_to_version(file_contents, file_path) do
    file_contents
    |> Code.string_to_quoted!(file: file_path)
    |> Scapa.Code.defined_modules()
    |> Enum.flat_map(&Scapa.Code.functions_with_doc({:module, &1, file_contents}))
    |> Enum.sort_by(&FunctionDefinition.line_number/1)
    |> Enum.reverse()
  end
end

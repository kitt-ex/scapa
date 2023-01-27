defmodule Scapa.CLI do
  @moduledoc false

  alias Scapa.Config
  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.VersionsStore
  alias Scapa.VersionStores.TagsStore

  @type change ::
          {SourceFile.operation(), FunctionDefinition.t(), SourceFile.line_number(),
           SourceFile.content(), SourceFile.content_line()}

  @type error :: {:error, term(), SourceFile.path()}

  @doc """
  Generates versions for files based on the given configuration.
  """
  @doc version: "MzQwMTI5OTU"
  @spec generate_versions(Config.t()) :: {:ok, [SourceFile.t()]} | {:error, [error()]}
  def generate_versions(%Config{include: files_patterns} = config) do
    versions_store = version_store_from_config(config)
    source_files = load_source_files(files_patterns)

    case Enum.filter(source_files, &(elem(&1, 0) == :error)) do
      [] ->
        {:ok,
         source_files
         |> Enum.map(&elem(&1, 1))
         |> Enum.map(&inject_function_versions(&1, versions_store))
         |> Enum.map(&SourceFile.generate_doc_version_changes/1)}

      errors ->
        {:error, errors}
    end
  end

  @doc """
  Returns up to date and outdated versions for functions based on the given configuration.
  """
  @doc version: "MTE5ODExODg"
  @spec check_versions(Config.t()) :: {:ok, [change()]} | {:error, [error()]}
  def check_versions(%Config{include: files_patterns} = config) do
    versions_store = version_store_from_config(config)
    source_files = load_source_files(files_patterns)

    case Enum.filter(source_files, &(elem(&1, 0) == :error)) do
      [] ->
        {:ok,
         source_files
         |> Enum.map(&elem(&1, 1))
         |> Enum.map(&inject_function_versions(&1, versions_store))
         |> Enum.map(&SourceFile.generate_doc_version_changes/1)
         |> Enum.map(&get_changes_to_make/1)}

      errors ->
        {:error, errors}
    end
  end

  defp load_source_files(file_patterns) do
    file_patterns
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.map(&Path.expand/1)
    |> MapSet.new()
    |> Enum.map(fn path ->
      case SourceFile.load_from_path(path) do
        {:ok, _} = result -> result
        {:error, reason} -> {:error, reason, path}
      end
    end)
  end

  defp version_store_from_config(_config), do: %TagsStore{}

  defp inject_function_versions(
         %SourceFile{documented_functions: documented_functions} = source_file,
         store
       ) do
    documented_functions =
      Enum.map(documented_functions, fn function ->
        %{function | version: VersionsStore.get_version(store, function)}
      end)

    %{source_file | documented_functions: documented_functions}
  end

  defp get_changes_to_make(%SourceFile{changeset: changeset} = source_file) do
    updates =
      changeset
      |> Enum.map(fn {operation, line_number, new_content, metadata} ->
        chunk = SourceFile.get_chunk(source_file, line_number: line_number, lines: 3)

        {operation, metadata[:origin], line_number, chunk, new_content}
      end)
      |> Enum.sort_by(fn {_, _, line_number, _, _} -> line_number end)

    {source_file, updates}
  end
end

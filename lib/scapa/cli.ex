defmodule Scapa.CLI do
  @moduledoc false

  alias Scapa.Config
  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.SyncService
  alias Scapa.VersionCalculator

  @type error :: {:error, term(), SourceFile.path()}

  @doc """
  Generates versions for files based on the given configuration.
  """
  @doc version: "MzQwMTI5OTU"
  @spec generate_versions(Config.t()) :: {:ok, [SyncService.change()]} | {:error, [error()]}
  def generate_versions(%Config{include: files_patterns}) do
    files_patterns
    |> load_source_files()
    |> unwrap(fn source_files ->
      versions =
        source_files
        |> Enum.map(&VersionCalculator.calculate/1)
        |> Enum.reduce(&Map.merge/2)

      {:ok,
       source_files
       |> Enum.flat_map(&SyncService.sync_steps(&1, versions))}
    end)
  end

  @doc """
  Returns up to date and outdated versions for functions based on the given configuration.
  """
  @doc version: "MTE5ODExODg"
  @spec check_versions(Config.t()) ::
          {:ok, [{SourceFile.t(), SyncService.change()}]} | {:error, [error()]}
  def check_versions(%Config{include: files_patterns}) do
    files_patterns
    |> load_source_files()
    |> unwrap(fn source_files ->
      versions =
        source_files
        |> Enum.map(&VersionCalculator.calculate/1)
        |> Enum.reduce(&Map.merge/2)

      {:ok,
       source_files
       |> Enum.flat_map(&SyncService.sync_steps(&1, versions))
       |> get_changes_to_make(source_files)}
    end)
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

  defp get_changes_to_make(changes, source_files) do
    changes = Enum.group_by(changes, fn {_, {source_file, _}, _, _} -> source_file end)

    Enum.map(source_files, fn source_file ->
      local_changes =
        changes
        |> Map.get(source_file, [])
        |> Enum.sort_by(fn {_, {_, line_number}, _, _} -> line_number end)

      {source_file, local_changes}
    end)
  end

  defp unwrap(results, on_success) do
    case Enum.filter(results, &(elem(&1, 0) == :error)) do
      [] ->
        results
        |> Enum.map(&elem(&1, 1))
        |> on_success.()

      errors ->
        {:error, errors}
    end
  end
end

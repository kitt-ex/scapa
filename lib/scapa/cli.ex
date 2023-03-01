defmodule Scapa.CLI do
  @moduledoc false

  alias Scapa.Config
  alias Scapa.SourceFile
  alias Scapa.SyncBackends.TagsSync
  alias Scapa.SyncBackends.VersionsFileSync
  alias Scapa.SyncService

  @type error :: {:error, term(), SourceFile.path()}

  @doc """
  Generates versions for files based on the given configuration.
  """
  @doc version: "MzQwMTI5OTU"
  @spec generate_versions(Config.t()) :: {:ok, SyncService.t()} | {:error, [error()]}
  def generate_versions(%Config{include: files_patterns} = config) do
    files_patterns
    |> load_source_files()
    |> unwrap(fn source_files ->
      sync = get_sync(config, source_files)

      {:ok,
       source_files
       |> Enum.reduce(sync, &SyncService.sync_steps(&2, &1))}
    end)
  end

  @doc """
  Returns up to date and outdated versions for functions based on the given configuration.
  """
  @doc version: "MTE5ODExODg"
  @spec check_versions(Config.t()) ::
          {:ok, [{SourceFile.t(), SyncService.change()}]} | {:error, [error()]}
  def check_versions(%Config{include: files_patterns} = config) do
    files_patterns
    |> load_source_files()
    |> unwrap(fn source_files ->
      sync = get_sync(config, source_files)

      {:ok,
       source_files
       |> Enum.reduce(sync, &SyncService.sync_steps(&2, &1))
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

  defp get_changes_to_make(%TagsSync{} = sync, source_files) do
    changes = Enum.group_by(sync.changeset, fn {_, {source_file, _}, _, _} -> source_file end)

    Enum.map(source_files, fn source_file ->
      local_changes =
        changes
        |> Map.get(source_file, [])
        |> Enum.sort_by(fn {_, {_, line_number}, _, _} -> line_number end)

      {source_file, local_changes}
    end)
  end

  defp get_changes_to_make(%VersionsFileSync{changeset: changeset} = sync, _source_files) do
    [source_file] = SyncService.apply_changeset(sync)

    [{source_file, changeset}]
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

  defp get_sync(%Config{store: :tags}, source_files), do: TagsSync.new(source_files)
  defp get_sync(config, _source_files), do: VersionsFileSync.new(config)
end

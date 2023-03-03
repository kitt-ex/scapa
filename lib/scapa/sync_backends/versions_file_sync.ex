defmodule Scapa.SyncBackends.VersionsFileSync do
  @moduledoc false
  alias Scapa.Config
  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.SyncBackends.VersionsFileSync
  alias Scapa.SyncService
  alias Scapa.VersionCalculator

  defstruct [:versions, :file_path, changeset: []]

  @doc """
  Reads the versions file from the config and returns a VersionsFileSync struct
  with that data.
  """
  @spec new(Config.t()) :: %VersionsFileSync{}
  @doc version: "Mjc3MTI5ODI"
  def new(config) do
    file_path = Config.versions_file(config)

    if File.exists?(file_path) do
      {versions, _} = Code.eval_file(file_path)
      versions = versions || %{}

      unless is_map(versions) do
        raise ArgumentError,
              "Expected #{inspect(file_path)} to return a map, got: #{inspect(versions)}"
      end

      %__MODULE__{versions: versions || %{}, file_path: file_path}
    else
      raise RuntimeError, "trying to read versions file but #{file_path} does not exist"
    end
  end

  defimpl SyncService do
    @doc """
    Adds a list of changes to the changeset to follow to get the versions saved in sync with the
    versions calculated out of the source code.
    """
    @spec sync_steps(%VersionsFileSync{}, SourceFile.t()) :: %VersionsFileSync{}
    def sync_steps(
          %VersionsFileSync{
            versions: function_versions,
            file_path: file_path,
            changeset: changeset
          } = sync,
          %SourceFile{documented_functions: documented_functions} = source_file
        ) do
      new_versions = VersionCalculator.calculate(source_file)

      documented_functions
      |> Enum.map(fn %FunctionDefinition{signature: signature} = function_definition ->
        {m, f, a, _} = signature
        old_version = function_versions[{m, f, a}]
        new_version = new_versions[signature]

        cond do
          old_version == nil && new_version != nil ->
            insert_new_entry(file_path, function_definition, new_version)

          new_version != old_version ->
            update_entry(file_path, function_definition, new_version)

          true ->
            :noop
        end
      end)
      |> Enum.reject(&(&1 == :noop))
      |> then(&%{sync | changeset: changeset ++ &1})
    end

    @doc """
    Applies the changes in the changeset returning a new versions SourceFile with
    the updated data.
    """
    @spec apply_changeset(%VersionsFileSync{}) :: [SourceFile.t()]
    def apply_changeset(%VersionsFileSync{
          versions: function_versions,
          changeset: changeset,
          file_path: file_path
        }) do
      changeset
      |> merge_changeset(function_versions)
      |> stringify_versions()
      |> then(&[%SourceFile{contents: &1, path: file_path, documented_functions: []}])
    end

    defp insert_new_entry(
           file_path,
           %FunctionDefinition{signature: {m, f, a, _}} = function_definition,
           new_version
         ) do
      entry = {{m, f, a}, new_version}
      {:insert, file_path, entry, [origin: function_definition]}
    end

    defp update_entry(
           file_path,
           %FunctionDefinition{signature: {m, f, a, _}} = function_definition,
           new_version
         ) do
      entry = {{m, f, a}, new_version}

      {:update, file_path, entry, [origin: function_definition]}
    end

    defp merge_changeset(changeset, function_versions) do
      changeset
      |> Enum.map(&elem(&1, 2))
      |> Enum.sort()
      |> Enum.reduce(function_versions, fn {key, value}, versions ->
        Map.put(versions, key, value)
      end)
    end

    defp stringify_versions(versions) do
      versions
      |> inspect(pretty: true)
      |> String.split("\n")
      |> then(& &1 ++ ["\n"])
    end
  end
end

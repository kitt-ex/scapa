defmodule Scapa.SyncBackends.TagsSync do
  @moduledoc false
  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.SyncBackends.TagsSync
  alias Scapa.SyncService
  alias Scapa.VersionCalculator

  defstruct [:versions, changeset: []]

  @doc """
  Calculates the versions from the given Source Files and returns
  a TagSync struct.
  """
  @spec new([SourceFile.t()]) :: %TagsSync{}
  @doc version: "Mjg3Nzk3MDY"
  def new(source_files) do
    versions =
      source_files
      |> Enum.map(&VersionCalculator.calculate/1)
      |> Enum.reduce(&Map.merge/2)

    %__MODULE__{versions: versions}
  end

  defimpl SyncService do
    @doc """
    Adds a list of changes to the changeset to follow to get the versions saved in sync with the
    versions calculated out of the source code.
    """
    @spec sync_steps(%TagsSync{}, SourceFile.t()) :: %TagsSync{}
    def sync_steps(
          %TagsSync{versions: function_versions, changeset: changeset} = sync,
          %SourceFile{documented_functions: documented_functions} = source_file
        ) do
      documented_functions
      |> Enum.map(fn %FunctionDefinition{signature: signature, version: old_version} =
                       function_definition ->
        new_version = function_versions[signature]

        cond do
          old_version == nil && new_version != nil ->
            insert_doc_tag(source_file, function_definition, new_version)

          new_version != old_version ->
            update_doc_tag(source_file, function_definition, new_version, source_file)

          true ->
            :noop
        end
      end)
      |> Enum.reject(&(&1 == :noop))
      |> then(&%{sync | changeset: changeset ++ &1})
    end

    @doc """
    Applies the changes in the changeset to the listed source files, returning new ones
    with their contents updated.
    """
    @spec apply_changeset(%TagsSync{}) :: [SourceFile.t()]
    def apply_changeset(%TagsSync{changeset: changeset}) do
      operation_order = %{insert: 0, update: 1}

      changeset
      |> Enum.group_by(fn {_, {source_file, _}, _, _} -> source_file end)
      |> Enum.map(fn {source_file, local_changesets} ->
        local_changesets
        |> Enum.sort_by(
          fn {operation, {_, file_number}, _, _} -> {operation_order[operation], file_number} end,
          :desc
        )
        |> Enum.reduce(source_file, fn
          {:update, {_, line_number}, new_content, _}, source_file ->
            SourceFile.replace(source_file, line_number, new_content)

          {:insert, {_, line_number}, new_content, _}, source_file ->
            SourceFile.insert(source_file, line_number, new_content)
        end)
      end)
    end

    defp insert_doc_tag(source_file, function_definition, new_version) do
      doc_tag = quote(do: @doc(version: unquote(new_version)))

      doc_tag_line =
        String.duplicate(" ", FunctionDefinition.column_number(function_definition) - 1) <>
          Macro.to_string(doc_tag)

      {:insert, {source_file, FunctionDefinition.line_number(function_definition) - 1},
       doc_tag_line, [origin: function_definition]}
    end

    defp update_doc_tag(
           source_file,
           %FunctionDefinition{version: old_version} = function_definition,
           new_version,
           source_file
         ) do
      {doc_tag_line, old_doc_tag} = SourceFile.find_line(source_file, ~r/"#{old_version}"/)
      new_doctag = Regex.replace(~r/"#{old_version}"/, old_doc_tag, ~s{"#{new_version}"})

      {:update, {source_file, doc_tag_line}, new_doctag, [origin: function_definition]}
    end
  end
end

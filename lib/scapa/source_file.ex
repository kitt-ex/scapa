defmodule Scapa.SourceFile do
  @moduledoc false

  defstruct [:path, :contents, :documented_functions, :changeset]

  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.VersionCalculator

  @type t :: %__MODULE__{
          path: path(),
          contents: [content_line()],
          documented_functions: [FunctionDefinition.t()],
          changeset: MapSet.t(change())
        }

  @type path :: String.t()
  @type content_line :: String.t()
  @type change :: {operation(), line_number(), content(), metadata()}
  @type line_number :: non_neg_integer()
  @type operation :: :insert | :update
  @type content :: String.t()
  @typep metadata :: Keyword.t()

  @doc """
  Returns whether or not a source file has changes to be applied.

  ## Examples

      iex> Scapa.SourceFile.changes?(%Scapa.SourceFile{changeset: MapSet.new()})
      false

      iex> Scapa.SourceFile.changes?(%Scapa.SourceFile{changeset: MapSet.new([{:insert, 2, "something", []}])})
      true
  """
  @spec changes?(SourceFile.t()) :: boolean
  @doc version: "OTI5NjAzMTY"
  def changes?(%SourceFile{changeset: changeset}), do: Enum.any?(changeset)

  @doc """
  Returns a portion of the contents as a list of strings.

    ## Examples

      iex> source_file = %Scapa.SourceFile{contents: ["123", "abc", "xyz", "789"]}
      ...> Scapa.SourceFile.get_chunk(source_file, line_number: 1, lines: 2)
      ["abc", "xyz"]
  """
  @spec get_chunk(Scapa.SourceFile.t(), line_number: line_number(), lines: non_neg_integer) :: [
          content_line()
        ]
  @doc version: "MzA2Njk2Nzk"
  def get_chunk(%SourceFile{contents: contents}, line_number: line_number, lines: lines),
    do: Enum.slice(contents, line_number, lines)

  @doc """
  Returns the contents of the source file as a string to be written to disk.

    ## Examples

      iex> source_file = %Scapa.SourceFile{contents: ["123", "abc", "xyz", "789"]}
      ...> Scapa.SourceFile.writtable_contents(source_file)
      "123
      abc
      xyz
      789"
  """
  @spec writtable_contents(Scapa.SourceFile.t()) :: String.t()
  @doc version: "OTYxNDg1Mzk"
  def writtable_contents(%SourceFile{contents: contents}), do: Enum.join(contents, "\n")

  @doc """
  Returns a SourceFile representing the file on the given path.
  """
  @spec load_from_path(path()) :: {:error, atom} | {:ok, Scapa.SourceFile.t()}
  @doc version: "ODI4NzI1ODQ"
  def load_from_path(file_path) do
    with {:ok, contents} <- File.read(file_path),
         ast <- Code.string_to_quoted(contents, file: file_path, columns: true),
         modules <- Scapa.Code.defined_modules(ast),
         documented_functions <-
           Enum.flat_map(modules, &Scapa.Code.functions_with_doc({:module, &1, contents})) do
      {:ok,
       %SourceFile{
         path: file_path,
         contents: String.split(contents, "\n"),
         documented_functions: documented_functions,
         changeset: MapSet.new()
       }}
    else
      error ->
        error
    end
  end

  @doc """
  Generates changes for the functions in the sourfe file so that all versions
  are present and up to date.
  """
  @spec generate_doc_version_changes(Scapa.SourceFile.t()) :: SourceFile.t()
  @doc version: "MzU1Mzg3NzA"
  def generate_doc_version_changes(
        %SourceFile{documented_functions: documented_functions} = source_file
      ) do
    documented_functions
    |> Enum.map(&{VersionCalculator.calculate(&1), &1})
    |> Enum.reduce(source_file, fn
      {new_version, %FunctionDefinition{version: nil} = function_definition},
      %SourceFile{changeset: changeset} = source_file ->
        %{
          source_file
          | changeset: MapSet.put(changeset, insert_doc_tag(function_definition, new_version))
        }

      {new_version, %FunctionDefinition{version: old_version} = function_definition},
      %SourceFile{changeset: changeset} = source_file
      when new_version != old_version ->
        %{
          source_file
          | changeset:
              MapSet.put(changeset, update_doc_tag(function_definition, new_version, source_file))
        }

      _, source_file ->
        source_file
    end)
  end

  @doc """
  Applies the changes in the changeset to the source file, returning a new one
  with the contents updated. The changes are treated as applied and the changeset is resetted.

      ## Examples

      iex> changeset = MapSet.new([{:insert, 0, "First!", []}, {:update, 0, "456", []}])
      ...> source_file = %Scapa.SourceFile{contents: ["123", "abc", "xyz", "789"], changeset: changeset}
      ...> Scapa.SourceFile.apply_changeset(source_file)
      %Scapa.SourceFile{contents: ["First!", "456", "abc", "xyz", "789"], changeset: MapSet.new()}
  """
  @spec apply_changeset(Scapa.SourceFile.t()) :: Scapa.SourceFile.t()
  @doc version: "NTkzNTkzMzA"
  def apply_changeset(%SourceFile{changeset: changeset, contents: contents} = source_file) do
    updates = Enum.filter(changeset, &(elem(&1, 0) == :update))
    inserts = Enum.filter(changeset, &(elem(&1, 0) == :insert))

    contents =
      contents
      |> apply_updates(updates)
      |> apply_inserts(inserts)

    %{source_file | contents: contents, changeset: MapSet.new()}
  end

  defp insert_doc_tag(function_definition, new_version) do
    doc_tag = quote(do: @doc(version: unquote(new_version)))

    doc_tag_line =
      String.duplicate(" ", FunctionDefinition.column_number(function_definition) - 1) <>
        Macro.to_string(doc_tag)

    {:insert, FunctionDefinition.line_number(function_definition) - 1, doc_tag_line,
     [origin: function_definition]}
  end

  defp update_doc_tag(
         %FunctionDefinition{version: old_version} = function_definition,
         new_version,
         %SourceFile{
           contents: contents
         }
       ) do
    doc_tag_line = Enum.find_index(contents, &Regex.match?(~r/"#{old_version}"/, &1))
    old_doc_tag = Enum.at(contents, doc_tag_line)
    new_doctag = Regex.replace(~r/"#{old_version}"/, old_doc_tag, ~s{"#{new_version}"})

    {:update, doc_tag_line, new_doctag, [origin: function_definition]}
  end

  defp apply_updates(contents, updates) do
    Enum.reduce(updates, contents, fn {:update, line_number, new_content, _meta}, contents ->
      List.replace_at(contents, line_number, new_content)
    end)
  end

  defp apply_inserts(contents, inserts) do
    inserts
    |> Enum.sort_by(
      fn {:insert, line_number, _content, _meta} -> line_number end,
      :desc
    )
    |> Enum.reduce(contents, fn {:insert, line_number, new_content, _meta}, contents ->
      List.insert_at(contents, line_number, new_content)
    end)
  end
end

defmodule Scapa.SourceFile do
  @moduledoc false

  defstruct [:path, :contents, :documented_functions]

  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile

  @type t :: %__MODULE__{
          path: path(),
          contents: [content_line()],
          documented_functions: [FunctionDefinition.t()]
        }

  @type path :: String.t()
  @type content_line :: String.t()
  @type line_number :: non_neg_integer()
  @type content :: String.t()

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
      ...> Scapa.SourceFile.writeable_contents(source_file)
      "123
      abc
      xyz
      789"
  """
  @spec writeable_contents(Scapa.SourceFile.t()) :: String.t()
  @doc version: "OTM4MzI4Ng"
  def writeable_contents(%SourceFile{contents: contents}), do: Enum.join(contents, "\n")

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
         documented_functions: documented_functions
       }}
    else
      error ->
        error
    end
  end

  @doc """
  Returns the index and the content of the first line that matches the given pattern.

    ## Examples

    iex> source_file = %Scapa.SourceFile{contents: ["123", "abc", "xyz", "xxx"]}
    ...> Scapa.SourceFile.find_line(source_file, ~r{^x})
    {2, "xyz"}
  """
  @spec find_line(Scapa.SourceFile.t(), Regex.t()) :: {non_neg_integer, String.t()}
  @doc version: "OTI2MzUyNTM"
  def find_line(%SourceFile{contents: contents}, pattern) do
    line_number = Enum.find_index(contents, &Regex.match?(pattern, &1))

    {line_number, Enum.at(contents, line_number)}
  end

  @doc """
  Replaces the content on the given line with the new content given.

    ## Examples

    iex> source_file = %Scapa.SourceFile{contents: ["123", "abc", "xyz", "789"]}
    ...> source_file = Scapa.SourceFile.replace(source_file, 2, "replaced")
    ...> Scapa.SourceFile.writeable_contents(source_file)
    "123
    abc
    replaced
    789"
  """
  @spec replace(Scapa.SourceFile.t(), integer, String.t()) :: Scapa.SourceFile.t()
  @doc version: "NDgyMDM4NDM"
  def replace(%SourceFile{contents: contents} = source_file, line_number, new_content) do
    %{source_file | contents: List.replace_at(contents, line_number, new_content)}
  end

  @doc """
  Inserts the given content on the specified line.

    ## Examples

    iex> source_file = %Scapa.SourceFile{contents: ["123", "abc", "xyz", "789"]}
    ...> source_file = Scapa.SourceFile.insert(source_file, 2, "inserted")
    ...> Scapa.SourceFile.writeable_contents(source_file)
    "123
    abc
    inserted
    xyz
    789"
  """
  @spec insert(Scapa.SourceFile.t(), integer, String.t()) :: Scapa.SourceFile.t()
  @doc version: "MzgwMjc2NTU"
  def insert(%SourceFile{contents: contents} = source_file, line_number, new_content) do
    %{source_file | contents: List.insert_at(contents, line_number, new_content)}
  end
end

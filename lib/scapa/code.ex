defmodule Scapa.Code do
  @moduledoc false
  alias Scapa.FunctionDefinition

  @type source() :: {:module, module(), source_code()}
  @type source_code() :: String.t()
  @type ast() :: Macro.t()

  @doc """
  Returns a FunctionDefinition for each function present in the source with a
  @doc tag.
  """
  @spec functions_with_doc(source()) :: [FunctionDefinition.t()]
  @doc version: "74559578"
  def functions_with_doc({:module, module, module_source}) do
    docs = function_docs(module)
    ast = Code.string_to_quoted!(module_source, columns: true)

    docs
    |> Enum.filter(&has_doc?/1)
    |> Enum.map(fn
      {{:function, name, arity}, doc_start, [string_signature], _, metadata} ->
        %FunctionDefinition{
          signature: {module, name, arity, string_signature},
          version: metadata[:version],
          position: function_position(doc_start, ast)
        }
    end)
  end

  @doc """
  Updates the doc on the given module source code for a funtions definition with the
  passed new version. If the version did not previosly exist then it's inserted.
  """
  @spec upsert_doc_version(source_code(), FunctionDefinition.t(), FunctionDefinition.version()) ::
          source_code()
  @doc version: "88390810"
  def upsert_doc_version(module_string, function_definition, new_version)

  def upsert_doc_version(
        module_string,
        %FunctionDefinition{version: nil, position: {line, column}},
        new_version
      ) do
    module_string
    |> String.split("\n")
    |> List.insert_at(line - 1, String.duplicate(" ", column - 1) <> doc_tag(new_version))
    |> Enum.join("\n")
  end

  def upsert_doc_version(module_string, %FunctionDefinition{version: old_version}, new_version)
      when not is_nil(old_version) do
    Regex.replace(~r/version:\W*"#{old_version}"/, module_string, ~s{version: "#{new_version}"})
  end

  @doc """
  Returns the modules defined in an AST as modules.

  ## Examples
    iex> ast = quote do defmodule Scapa do defmodule Scapa.Insider, do: nil end end
    iex> Scapa.Code.defined_modules(ast)
    [Scapa.Insider, Scapa]
  """
  @spec defined_modules(Macro.t()) :: [atom()]
  @doc version: "84273486"
  def defined_modules(ast) do
    ast
    |> Macro.prewalk([], fn
      {:defmodule, _, [{:__aliases__, _, module_name} | _]} = t, acc ->
        {t, [module_name | acc]}

      t, acc ->
        {t, acc}
    end)
    |> elem(1)
    |> Enum.map(&Enum.join(["Elixir"] ++ &1, "."))
    |> Enum.map(&String.to_atom/1)
  end

  defp function_position(doc_start, ast) do
    ast
    |> Macro.prewalk([], fn
      {:def, [line: line, column: column], _} = t, acc when line >= doc_start ->
        {t, [{line, column} | acc]}

      t, acc ->
        {t, acc}
    end)
    |> elem(1)
    |> Enum.min()
  end

  defp has_doc?({_, _, _, doc_content, _}) when doc_content in [:none, :hidden], do: false
  defp has_doc?(_), do: true

  defp function_docs(module) do
    {:docs_v1, _, :elixir, _, _, _, docs} = Code.fetch_docs(module)

    docs
  end

  defp doc_tag(version) do
    Macro.to_string(
      quote do
        @doc version: unquote(version)
      end
    )
  end
end

defmodule Scapa.Code do
  @moduledoc false
  alias Scapa.FunctionDefinition

  @type source() :: {:module, module()}
  @type source_code() :: String.t()

  @doc """
  Returns a FunctionDefinition for each function present in the source with a
  @doc tag.
  """
  @spec functions_with_doc([source()]) :: [FunctionDefinition.t()]
  def functions_with_doc(sources) do
    Enum.flat_map(sources, fn {:module, module} -> docs_from_module(module) end)
  end

  @doc """
  Updates the doc on the given module source code for a funtions definition with the
  passed new version. If the version did not previosly exist then it's inserted.
  """
  @spec upsert_doc_version(source_code(), FunctionDefinition.t(), FunctionDefinition.version()) ::
          source_code()
  def upsert_doc_version(module_string, function_definition, new_version)

  def upsert_doc_version(
        module_string,
        %FunctionDefinition{version: nil} = function_definition,
        new_version
      ) do
    doc_start = doc_location(function_definition)
    {line, column} = doc_tag_position(module_string, doc_start)

    doc_tag =
      String.duplicate(" ", column - 1) <>
        Macro.to_string(
          quote do
            @doc version: unquote(new_version)
          end
        )

    module_string
    |> String.split("\n")
    |> List.insert_at(line - 1, doc_tag)
    |> Enum.join("\n")
  end

  def upsert_doc_version(module_string, %FunctionDefinition{version: old_version}, new_version)
      when not is_nil(old_version) do
    Regex.replace(~r/version:\W*"#{old_version}"/, module_string, ~s{version: "#{new_version}"})
  end

  @doc """
  Returns the line where the @doc tag is located for a given funtion
  """
  @spec doc_location(FunctionDefinition.t()) :: nil | pos_integer()
  def doc_location(%FunctionDefinition{signature: {module, name, arity, _}}) do
    docs = function_docs(module)

    Enum.find_value(docs, fn
      {{:function, ^name, ^arity}, line_number, _, _, _} -> line_number
      _ -> nil
    end)
  end

  defp docs_from_module(module) do
    docs = function_docs(module)

    docs
    |> Enum.filter(&has_doc?/1)
    |> Enum.map(fn
      {{:function, name, arity}, _, [string_signature], _, metadata} ->
        %FunctionDefinition{
          signature: {module, name, arity, string_signature},
          version: metadata[:version]
        }
    end)
  end

  defp has_doc?({_, _, _, doc_content, _}) when doc_content in [:none, :hidden], do: false
  defp has_doc?(_), do: true

  defp doc_tag_position(module_string, doc_start) do
    module_string
    |> Code.string_to_quoted!(columns: true)
    |> Macro.prewalk([], fn
      {:def, [line: line, column: column], _} = t, acc when line >= doc_start ->
        {t, [{line, column} | acc]}

      t, acc ->
        {t, acc}
    end)
    |> elem(1)
    |> Enum.min()
  end

  defp function_docs(module) do
    {:docs_v1, _, :elixir, _, _, _, docs} = Code.fetch_docs(module)

    docs
  end
end

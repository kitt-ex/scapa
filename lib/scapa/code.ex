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
  @doc version: "NzQ1NTk1Nzg"
  def functions_with_doc({:module, module, module_source}) do
    docs = function_docs(module)
    source_functions = functions_defined_in_source(module_source)

    docs
    |> Enum.filter(fn function_doc ->
      has_doc?(function_doc) && defined_in_source?(function_doc, source_functions)
    end)
    |> Enum.map(fn
      {{_, name, arity}, _annotation, [string_signature], doc_content, metadata} ->
        %FunctionDefinition{
          signature: {module, name, arity, string_signature},
          version: metadata[:version],
          position: function_position!({name, arity}, source_functions),
          doc: doc_content["en"]
        }
    end)
  end

  @doc """
  Returns the modules defined in an AST as modules.
  """
  @spec defined_modules(Macro.t(), [String.t()]) :: [atom()]
  @doc version: "OTQyMjEzMjI"
  def defined_modules(ast, prefix \\ ["Elixir"]) do
    ast
    |> Macro.prewalk([], fn
      {:defmodule, _, [{:__aliases__, _, module_name} | inner]} = t, acc ->
        module_name = Enum.map(module_name, &Atom.to_string/1)
        inner_modules = defined_modules(inner, prefix ++ module_name)
        acc = inner_modules ++ acc

        case get_module(module_name, prefix) do
          {:module, module} ->
            {t, [module | acc]}

          {:error, _} ->
            {t, acc}
        end

      t, acc ->
        {t, acc}
    end)
    |> elem(1)
  end

  @doc """
  Returns the prettified representation of the term, ready to be written to a file.

  ## Example
    iex> Scapa.Code.stringify([include: "lib/**/*.ex", store: :tags])
    ~s([include: "lib/**/*.ex", store: :tags])

  """
  @spec stringify(term()) :: String.t()
  @doc version: "MTAyNzU5NjQ1"
  def stringify(term) do
    term
    |> inspect(pretty: true)
  end

  defp functions_defined_in_source(module_source) do
    update_known_functions = fn known_functions, func_name, args, metadata ->
      arity = args |> List.wrap() |> Enum.count()
      function = {func_name, arity}
      position = {metadata[:line], metadata[:column]}

      Map.update(known_functions, function, position, &min(&1, position))
    end

    module_source
    |> Code.string_to_quoted!(columns: true)
    |> Macro.prewalk(%{}, fn
      # def with guard
      {def_type, metadata, [{:when, _, [{func_name, _, args}, _]}, _inner]} = t, known_functions
      when def_type in [:def, :defmacro] ->
        {t, update_known_functions.(known_functions, func_name, args, metadata)}

      # def without body (function head)
      {def_type, metadata, [{func_name, _meta, args}]} = t, known_functions
      when def_type in [:def, :defmacro] ->
        {t, update_known_functions.(known_functions, func_name, args, metadata)}

      # normal def
      {def_type, metadata, [{func_name, _meta, args}, _inner]} = t, known_functions
      when def_type in [:def, :defmacro] ->
        {t, update_known_functions.(known_functions, func_name, args, metadata)}

      t, known_functions ->
        {t, known_functions}
    end)
    |> elem(1)
  end

  defp function_position!({name, arity}, source_functions),
    do: Map.fetch!(source_functions, {name, arity})

  defp has_doc?({_, _, _, doc_content, _}) when doc_content in [:none, :hidden], do: false
  defp has_doc?(_), do: true

  defp defined_in_source?({{_, function_name, arity}, _, _, _, _}, source_functions),
    do: Map.has_key?(source_functions, {function_name, arity})

  defp function_docs(module) do
    {:docs_v1, _, :elixir, _, _, _, docs} = Code.fetch_docs(module)

    Enum.filter(docs, fn
      {{def_type, _, _}, _, _, _, _} when def_type in [:function, :macro] -> true
      _ -> false
    end)
  end

  defp get_module(name, prefix) do
    (prefix ++ name)
    |> Enum.join(".")
    |> String.to_existing_atom()
    |> Code.ensure_compiled()
  rescue
    ArgumentError ->
      {:error, :nonexistent_atom}
  end
end

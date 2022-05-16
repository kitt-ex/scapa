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
    source_functions = functions_defined_in_source(module_source)

    docs
    |> Enum.filter(fn function_doc ->
      has_doc?(function_doc) && defined_in_source?(function_doc, source_functions)
    end)
    |> Enum.map(fn
      {{_, name, arity}, _, [string_signature], _, metadata} ->
        %FunctionDefinition{
          signature: {module, name, arity, string_signature},
          version: metadata[:version],
          position: function_position!({name, arity}, source_functions)
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

  def get_change(
        module_string,
        %FunctionDefinition{version: nil, position: {line, _}},
        new_version,
        file_path
      ) do
    function = get_function_string(module_string, line)
    {:ok, :missing_version, new_version, function, file_path}
  end

  def get_change(
        module_string,
        %FunctionDefinition{version: old_version, position: {line, _}},
        new_version,
        file_path
      )
      when not is_nil(old_version) and new_version != old_version do
    function = get_function_string(module_string, line)
    {:ok, :outdated_version, new_version, function, file_path}
  end

  def get_change(_, _, _, _), do: nil

  defp get_function_string(module_string, line) do
    module_string
    |> String.split("\n")
    |> Enum.drop(line - 1)
    |> Enum.take(5)
    |> Enum.join("\n")
  end

  @doc """
  Returns the modules defined in an AST as modules.
  """
  @spec defined_modules(Macro.t(), [String.t()]) :: [atom()]
  @doc version: "94221322"
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

  defp doc_tag(version) do
    Macro.to_string(
      quote do
        @doc version: unquote(version)
      end
    )
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

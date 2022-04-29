defmodule Scapa.DocumentedFunctionsFinder do
  @moduledoc false
  alias Scapa.FunctionDefinition

  @type source() :: {:module, module()}

  @doc """
  Returns a FunctionDefinition for each function present in the source with a
  @doc tag.
  """
  @spec find_in([source()]) :: [FunctionDefinition.t()]
  def find_in(sources) do
    Enum.flat_map(sources, fn {:module, module} -> docs_from_module(module) end)
  end

  defp docs_from_module(module) do
    {:docs_v1, _, :elixir, _, _, _, docs} = Code.fetch_docs(module)

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
end

defmodule Scapa.VersionStores.TagsStore do
  alias Scapa.FunctionDefinition

  defstruct []

  defimpl Scapa.VersionsStore do
    @doc """
    Returns the version for the function definition, in this case we assume that the version was
    set from the tags before by `Scapa.Code.functions_with_doc/1` so we only need to fetch it from there.
    """
    @spec get_version(any, Scapa.FunctionDefinition.t()) :: Scapa.FunctionDefinition.version()
    def get_version(_store, %FunctionDefinition{version: version}) do
      version
    end
  end
end

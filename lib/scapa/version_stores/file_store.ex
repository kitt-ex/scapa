defmodule Scapa.VersionStores.FileStore do
  @moduledoc false
  alias Scapa.FunctionDefinition
  alias Scapa.VersionStores.FileStore

  defstruct [:versions]

  @doc """
  Create a new FileStore struct with the versions being the contents of the file from
  the file path argument. It raises an argument if either the file does not exist or if the
  content is something other than a map.
  """
  @doc version: "NDA5NzIyODM"
  def new(file_path) do
    if File.exists?(file_path) do
      {versions, _} = Code.eval_file(file_path)
      versions = versions || %{}

      unless is_map(versions) do
        raise ArgumentError,
              "Expected #{inspect(file_path)} to return a map, got: #{inspect(versions)}"
      end

      %__MODULE__{versions: versions || %{}}
    else
      raise RuntimeError, "trying to read versions file but #{file_path} does not exist"
    end
  end

  defimpl Scapa.VersionsStore do
    @doc """
    Returns the version for the function definition as stored in the struct
    versions attribute.
    """
    def get_version(%FileStore{versions: versions}, %FunctionDefinition{
          signature: {module, atom, arity, _}
        }) do
      versions[{module, atom, arity}]
    end
  end
end

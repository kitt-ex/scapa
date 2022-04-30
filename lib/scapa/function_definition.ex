defmodule Scapa.FunctionDefinition do
  @moduledoc false

  @type signature() :: {module(), atom(), arity(), String.t()}
  @type version() :: String.t()

  @type t :: %__MODULE__{
          signature: signature(),
          version: nil | version()
        }

  defstruct [:signature, :version]
end

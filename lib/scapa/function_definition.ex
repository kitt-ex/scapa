defmodule Scapa.FunctionDefinition do
  @moduledoc false

  @type signature() :: {module(), atom(), arity(), String.t()}

  @type t :: %__MODULE__{
    signature: signature(),
    version: nil | String.t()
  }

  defstruct [:signature, :version]
end

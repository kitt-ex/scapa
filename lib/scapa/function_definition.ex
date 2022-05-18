defmodule Scapa.FunctionDefinition do
  @moduledoc false

  @type signature() :: {module(), atom(), arity(), String.t()}
  @type version() :: String.t()
  @type position :: {line(), column()}
  @typep line() :: pos_integer()
  @typep column() :: pos_integer()

  @type t :: %__MODULE__{
          signature: signature(),
          version: nil | version(),
          position: position()
        }

  defstruct [:signature, :version, :position]

  @doc """
  Returns the line number for a function definition

  ## Example
    iex> Scapa.FunctionDefinition.line_number(%Scapa.FunctionDefinition{position: {42, 8}})
    42
  """
  @spec line_number(t()) :: line()
  @doc version: "NjM2NTY5NTA"
  def line_number(%__MODULE__{position: {line, _column}}), do: line
end

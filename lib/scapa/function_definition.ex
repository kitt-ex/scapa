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
          position: position(),
          doc: String.t()
        }

  defstruct [:signature, :version, :position, :doc]

  @doc """
  Returns the line number for a function definition

  ## Example
    iex> Scapa.FunctionDefinition.line_number(%Scapa.FunctionDefinition{position: {42, 8}})
    42
  """
  @spec line_number(t()) :: line()
  @doc version: "NjM2NTY5NTA"
  def line_number(%__MODULE__{position: {line, _column}}), do: line

  @doc """
  Returns the column number for a function definition

  ## Example
    iex> Scapa.FunctionDefinition.column_number(%Scapa.FunctionDefinition{position: {42, 8}})
    8
  """
  @spec column_number(t()) :: column()
  @doc version: "NDg0NjQzNTY"
  def column_number(%__MODULE__{position: {_line, column}}), do: column
end

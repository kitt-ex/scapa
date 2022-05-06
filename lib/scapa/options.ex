defmodule Scapa.Options do
  defstruct fix: false, pattern: "lib/**/*.ex", verbose: false

  def definition,
    do: [
      fix: :boolean,
      pattern: :string,
      verbose: :boolean
    ]
end

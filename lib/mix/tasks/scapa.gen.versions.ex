defmodule Mix.Tasks.Scapa.Gen.Versions do
  @moduledoc false

  @doc false
  def run(_argv) do
    for {path, content} <- Scapa.CLI.generate_versions(), do: File.write(path, content)
  end
end

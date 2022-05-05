defmodule Mix.Tasks.Scapa.Gen.Versions do
  @moduledoc false

  @default_file_pattern "lib/**/*.ex"

  @doc false
  def run(_argv) do
    for {path, content} <- Scapa.CLI.generate_versions(@default_file_pattern),
        do: File.write(path, content)
  end
end

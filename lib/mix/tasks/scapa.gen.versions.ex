defmodule Mix.Tasks.Scapa.Gen.Versions do
  @moduledoc false

  alias Scapa.Config

  @doc false
  def run(_argv) do
    config = Config.fetch_config()

    for {path, content} <- Scapa.CLI.generate_versions(config),
        do: File.write(path, content)
  end
end

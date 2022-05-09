defmodule Mix.Tasks.Scapa.Gen.Versions do
  @shortdoc "Generates or updates doc versions"
  @moduledoc """
  Generates versions for all `@doc` tags that are not false, if a version has
  already been generated then it's updated with a new value if needed.
  """

  use Mix.Task

  alias Scapa.Config

  @doc false
  @impl Mix.Task
  def run(_argv) do
    config = Config.fetch_config()

    for {path, content} <- Scapa.CLI.generate_versions(config),
        do: File.write(path, content)
  end
end

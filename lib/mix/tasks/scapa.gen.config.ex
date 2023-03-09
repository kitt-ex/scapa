defmodule Mix.Tasks.Scapa.Gen.Config do
  @shortdoc "Generates a config file"
  @moduledoc """
  Generates a config file with the default configuration.

  ## Command line options:
    - `--config-file` `-c` path to the config file to use. Defaults to .scapa.exs
  """

  use Mix.Task

  @requirements ["compile"]

  alias Scapa.Code
  alias Scapa.Config

  @doc false
  @impl Mix.Task
  def run(argv) do
    {parsed, _argv, _errors} =
      OptionParser.parse(argv, aliases: [c: :config_file], strict: [config_file: :string])

    content =
      Config.default_config()
      |> Code.stringify()

    File.write!(parsed[:config_file] || Config.default_config_path(), content)
  end
end

defmodule Mix.Tasks.Scapa.Gen.Versions do
  @shortdoc "Generates or updates doc versions"
  @moduledoc """
  Generates versions for all `@doc` tags that are not false, if a version has
  already been generated then it's updated with a new value if needed.
  """

  use Mix.Task

  @requirements ["compile"]

  alias Scapa.Config
  alias Scapa.SourceFile

  @doc false
  @impl Mix.Task
  def run(_argv) do
    config = Config.fetch_config()

    case Scapa.CLI.generate_versions(config) do
      {:ok, source_files} -> override_files(source_files)
      {:error, errors} -> show_errors(errors)
    end
  end

  defp override_files(new_source_files) do
    for %SourceFile{path: path} = source_file <- new_source_files,
        SourceFile.changes?(source_file) do
      source_file = SourceFile.apply_changeset(source_file)
      File.write!(path, SourceFile.writtable_contents(source_file))
    end
  end

  defp show_errors(errors) do
    for {:error, reason, path} <- errors do
      IO.puts(path)
      IO.puts(to_string(reason))
    end
  end
end

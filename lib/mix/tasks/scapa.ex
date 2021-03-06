defmodule Mix.Tasks.Scapa do
  @shortdoc "Validates that doc versions are up to date"
  @moduledoc """
  TODO
  """

  use Mix.Task

  @requirements ["compile"]

  alias Scapa.Config
  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile

  @doc false
  def run(_argv) do
    config = Config.fetch_config()

    case Scapa.CLI.check_versions(config) do
      {:ok, updates} ->
        updates
        |> Enum.map(&make_path_relative/1)
        |> Enum.each(&show_update/1)

      {:error, errors} ->
        show_errors(errors)
    end
  end

  defp show_update({%SourceFile{path: file_path}, []}),
    do: IO.puts(green("File #{file_path} is up to date."))

  defp show_update({%SourceFile{path: file_path}, updates}) do
    IO.puts(red("File #{file_path} has a function with a missing or outdated version number."))

    Enum.each(updates, fn {operation, function_definition, line_number, chunk, new_content} ->
      needed_change =
        if operation == :insert do
          List.insert_at(chunk, 0, bright(new_content))
        else
          List.replace_at(chunk, 0, bright(new_content))
        end

      IO.puts(
        "#{show_file_line(file_path, line_number)} #{show_function(function_definition)} #{if operation == :insert, do: "missing version", else: "outdated version"}"
      )

      IO.puts(Enum.join(needed_change, "\n"))
    end)
  end

  defp show_errors(errors) do
    for {:error, reason, path} <- errors do
      IO.puts(path)
      IO.puts(to_string(reason))
    end
  end

  defp show_function(%FunctionDefinition{signature: {module, name, arity, _}}) do
    Exception.format_mfa(module, name, arity)
  end

  def make_path_relative({%SourceFile{path: file_path} = source_file, changes}) do
    {%{source_file | path: Path.relative_to_cwd(file_path)}, changes}
  end

  def show_file_line(path, line), do: Exception.format_file_line(path, line)

  defp red(str), do: IO.ANSI.red() <> str <> reset()
  defp green(str), do: IO.ANSI.green() <> str <> reset()
  defp bright(str), do: IO.ANSI.bright() <> str <> reset()
  defp reset, do: IO.ANSI.reset()
end

defmodule Mix.Tasks.Scapa do
  @shortdoc "Validates that doc versions are up to date"
  @moduledoc """
  Gets the latest stored version of the documented functions
  based on the project config and arguments and compares it to
  the current status of the project source files. If there's functions with
  missing or outdated documentation it reports them so that they can be updated.

  This task does not modify any files.

  ## Command line options:
    - `--config-file` `-c` path to the config file to use. Defaults to .scapa.exs
  """

  use Mix.Task

  @requirements ["compile"]

  alias Scapa.Config
  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile

  @doc false
  def run(argv) do
    {parsed, _argv, _errors} =
      OptionParser.parse(argv, aliases: [c: :config_file], strict: [config_file: :string])

    config = Config.fetch_config(parsed[:config_file] || Config.default_config_path())

    case Scapa.CLI.check_versions(config) do
      {:ok, updates} ->
        updates
        |> Enum.map(&make_path_relative/1)
        |> Enum.each(&show_updates/1)

      {:error, errors} ->
        show_errors(errors)
    end
  end

  defp show_updates({%SourceFile{path: file_path}, []}),
    do: IO.puts(green("File #{file_path} is up to date."))

  defp show_updates({%SourceFile{path: file_path} = source_file, updates}) do
    IO.puts(red("File #{file_path} has a function with a missing or outdated version number."))

    Enum.each(updates, fn update ->
      IO.puts(update_text(source_file, update))
    end)
  end

  defp update_text(
         %SourceFile{path: file_path} = source_file,
         {operation, {_, line_number}, new_content, metadata}
       ) do
    chunk = SourceFile.get_chunk(source_file, line_number: line_number, lines: 3)

    function_definition = metadata[:origin]

    needed_change =
      if operation == :insert do
        List.insert_at(chunk, 0, bright(new_content))
      else
        List.replace_at(chunk, 0, bright(new_content))
      end

    "#{bright(show_file_line(file_path, line_number))} #{bright(show_function(function_definition))} #{prompt_text(operation, function_definition)}\n" <>
      Enum.join(needed_change, "\n")
  end

  defp update_text(%SourceFile{path: file_path}, {operation, _location, {key, value}, metadata}) do
    new_content = "#{inspect(key)} => #{inspect(value)},"

    function_definition = metadata[:origin]

    "#{bright(show_file_line(file_path, nil))} #{bright(show_function(function_definition))} #{prompt_text(operation, function_definition)}\n" <>
      bright(new_content)
  end

  defp prompt_text(:insert, _function_definition),
    do: bright("doc version is missing. Add to start tracking documentation versions:")

  defp prompt_text(_, %FunctionDefinition{doc: doc}) do
    bright("doc version is outdated. Current docs are:\n\n") <>
      doc <>
      bright("Check if the documentation is up to date and then update the doc version to:")
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

  defp make_path_relative({%SourceFile{path: file_path} = source_file, changes}) do
    {%{source_file | path: Path.relative_to_cwd(file_path)}, changes}
  end

  defp show_file_line(path, line), do: Exception.format_file_line(path, line)

  defp red(str), do: IO.ANSI.red() <> str <> reset()
  defp green(str), do: IO.ANSI.green() <> str <> reset()
  defp bright(str), do: IO.ANSI.bright() <> str <> reset()
  defp reset, do: IO.ANSI.reset()
end

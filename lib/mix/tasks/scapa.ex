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

      # line_number = if is_tuple(location), do: elem(location, 1)

      # new_content =
      #   if is_bitstring(new_content) do
      #     new_content
      #   else
      #     {key, value} = new_content
      #     "#{inspect(key)} => #{inspect(value)},"
      #   end

      # chunk =
      #   if line_number do
      #     SourceFile.get_chunk(source_file, line_number: line_number, lines: 3)
      #   else
      #     []
      #   end

      # function_definition = metadata[:origin]

      # needed_change =
      #   if operation == :insert do
      #     List.insert_at(chunk, 0, bright(new_content))
      #   else
      #     List.replace_at(chunk, 0, bright(new_content))
      #   end

      # IO.puts(
      #   "#{show_file_line(file_path, line_number)} #{show_function(function_definition)} #{if operation == :insert, do: "missing version", else: "outdated version"}"
      # )

      # IO.puts(Enum.join(needed_change, "\n"))
    end)
  end

  defp update_text(%SourceFile{path: file_path} = source_file, {operation, {_, line_number}, new_content, metadata}) do
    chunk = SourceFile.get_chunk(source_file, line_number: line_number, lines: 3)

    function_definition = metadata[:origin]

    needed_change =
      if operation == :insert do
        List.insert_at(chunk, 0, bright(new_content))
      else
        List.replace_at(chunk, 0, bright(new_content))
      end

      "#{show_file_line(file_path, line_number)} #{show_function(function_definition)} #{if operation == :insert, do: "missing version", else: "outdated version"}\n" <> Enum.join(needed_change, "\n")
  end

  defp update_text(%SourceFile{path: file_path}, {operation, _location, {key, value}, metadata}) do
    new_content = "#{inspect(key)} => #{inspect(value)},"

    function_definition = metadata[:origin]

    "#{show_file_line(file_path, nil)} #{show_function(function_definition)} #{if operation == :insert, do: "missing version", else: "outdated version"}\n" <> bright(new_content)
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

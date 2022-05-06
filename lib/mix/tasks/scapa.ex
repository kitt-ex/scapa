defmodule Mix.Tasks.Scapa do
  use Mix.Task

  @moduledoc false

  import IO, only: [puts: 1]

  alias Scapa.Options

  @possible_flags Options.definition()

  @doc false
  def run(argv) do
    args = parse_args(argv)
    versions = Scapa.CLI.generate_versions(args.pattern)
    apply_side_effect(versions, args.verbose, args.fix)
  end

  defp apply_side_effect(versions, verbose?, _fix = true), do: fix_versions(versions, verbose?)

  defp apply_side_effect(versions, _, _fix = false), do: check_versions(versions)

  defp check_versions(versions) do
    if length(versions) > 0 do
      for {path, _content} <- versions do
        puts("#{red()}Outdated documentation versions on file #{path}")
      end

      System.halt(1)
    end
  end

  defp fix_versions(versions, verbose?) do
    for {path, content} <- versions do
      if verbose? do
        puts("#{green()}Version updated on file #{path}")
      end

      File.write(path, content)
    end
  end

  defp parse_args(argv) do
    {keyword_list_of_args, _, _} = OptionParser.parse(argv, strict: @possible_flags)
    struct(Options, keyword_list_of_args)
  end

  defp red, do: IO.ANSI.red()
  defp green, do: IO.ANSI.green()
end

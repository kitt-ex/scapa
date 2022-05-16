defmodule Mix.Tasks.Scapa do
  @moduledoc false

  use Mix.Task

  @requirements ["compile"]

  alias Scapa.Config

  @doc false
  def run(_argv) do
    config = Config.fetch_config()

    results =
      config
      |> Scapa.CLI.generate_versions(_patch = true)
      |> Enum.group_by(&key_for_result/1)

    if is_nil(results[:errors]) do
      show_results(results)
    else
      show_errors(results[:errors])
    end
  end

  defp key_for_result({:ok, :no_changes, _file_path}), do: :no_changes
  defp key_for_result({:error, _error, _file_path}), do: :errors
  defp key_for_result({:ok, :missing_version, _, _, _}), do: :missing_versions
  defp key_for_result({:ok, :outdated_version, _, _, _}), do: :outdated_versions

  defp show_results(results) do
    if results[:no_changes] do
      for {_, _, file_path} <- results[:no_changes] do
        IO.puts("#{green()}File #{file_path} is up to date.")
      end
    end

    if results[:missing_versions] do
      for {_, _, version, function, file_path} <- results[:missing_versions] do
        IO.puts("#{red()}File #{file_path} has a function with missing version number.")

        IO.puts(
          "#{reset()}You should add #{bright()}@version \"#{version}\"#{reset()} on top of the following function:"
        )

        IO.puts(function)
      end
    end

    if results[:outdated_versions] do
      for {_, _, version, function, file_path} <- results[:outdated_versions] do
        IO.puts("#{red()}File #{file_path} has a function with an outdated version number.")

        IO.puts(
          "#{reset()}You should update the version tag with #{bright()}@version \"#{version}\"#{reset()} on the following function:"
        )

        IO.puts(function)
      end
    end
  end

  defp show_errors(errors) do
    for {:error, message, path} <- errors do
      IO.puts(path)
      IO.puts(message)
    end
  end

  defp red, do: IO.ANSI.red()
  defp green, do: IO.ANSI.green()
  defp bright, do: IO.ANSI.bright()
  defp reset, do: IO.ANSI.reset()
end

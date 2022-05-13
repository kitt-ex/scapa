defmodule Mix.Tasks.Scapa.Gen.Versions do
  @shortdoc "Generates or updates doc versions"
  @moduledoc """
  Generates versions for all `@doc` tags that are not false, if a version has
  already been generated then it's updated with a new value if needed.
  """

  use Mix.Task

  @requirements ["compile"]

  alias Scapa.Config

  @doc false
  @impl Mix.Task
  def run(_argv) do
    config = Config.fetch_config()

    results =
      config
      |> Scapa.CLI.generate_versions()
      |> Enum.group_by(&key_for_result/1)

    if is_nil(results[:errors]) do
      override_files(results[:override])
    else
      show_errors(results[:errors])
    end
  end

  defp key_for_result({:ok, :no_changes, _file_path}), do: :no_changes
  defp key_for_result({:ok, _new_content, _file_path}), do: :override
  defp key_for_result({:error, _error, _file_path}), do: :errors

  defp override_files(files_to_write) do
    for {:ok, content, path} <- List.wrap(files_to_write), do: File.write(path, content)
  end

  defp show_errors(errors) do
    for {:error, message, path} <- errors do
      IO.puts(path)
      IO.puts(message)
    end
  end
end

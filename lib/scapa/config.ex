defmodule Scapa.Config do
  @moduledoc false

  @type path :: String.t()
  @type t :: %__MODULE__{
          include: [path]
        }

  defstruct [:include]

  @config_path ".scapa.exs"
  @default_config [
    include: "lib/**/*.ex"
  ]

  @doc """
  Returns the config for the project if present and fills missing values from the
  default config. The default path for the config file is ".scapa.exs" and all
  options defined there should all be present in the Config struct.
  """
  @spec fetch_config(path) :: t()
  @doc version: "NjkwNDAzODQ"
  def fetch_config(path \\ @config_path) do
    @default_config
    |> merge_project_config(path)
    |> format_config()
    |> then(&struct!(__MODULE__, &1))
  end

  defp merge_project_config(config, path) do
    Keyword.merge(config, read_project_config(path))
  end

  defp read_project_config(path) do
    if File.exists?(path) do
      {opts, _} = Code.eval_file(path)

      unless Keyword.keyword?(opts) do
        raise ArgumentError,
              "Expected #{inspect(path)} to return a keyword list, got: #{inspect(opts)}"
      end

      opts
    else
      Keyword.new()
    end
  end

  defp format_config(config) do
    Keyword.update!(config, :include, &List.wrap/1)
  end
end

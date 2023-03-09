defmodule Scapa.Config do
  @moduledoc false

  @type path :: String.t()
  @type storage :: :tags | :file | {:file, path}
  @type t :: %__MODULE__{
          include: [path],
          store: storage
        }

  defstruct [:include, :store]

  @default_versions_file "priv/doc_versions.exs"

  @doc """
  Returns the config for the project if present and fills missing values from the
  default config. The default path for the config file is ".scapa.exs" and all
  options defined there should all be present in the Config struct.
  """
  @spec fetch_config(path) :: t()
  @doc version: "NzE2NTY5NDc"
  def fetch_config(path) do
    default_config()
    |> merge_project_config(path)
    |> format_config()
    |> then(&struct!(__MODULE__, &1))
  end

  @doc """
  Returns the default configuration options

  ### Example
    iex> Scapa.Config.default_config()
    [include: "lib/**/*.ex", store: :tags]
  """
  @spec default_config :: Keyword.t()
  @doc version: "Mzg3NDgyMg"
  def default_config do
    [
      include: "lib/**/*.ex",
      store: :tags
    ]
  end

  @doc """
  Returns the default config file path

  ### Example
    iex> Scapa.Config.default_config_path()
    ".scapa.exs"
  """
  @spec default_config_path :: path()
  @doc version: "NTEwNjkzNTk"
  def default_config_path, do: ".scapa.exs"

  @doc """
  Returns the path where the function versions should be stored or raises
  and error if the versions should not be stored in any file.
  """
  @spec versions_file(Scapa.Config.t()) :: path
  @doc version: "MTI0OTI2MDEz"
  def versions_file(%__MODULE__{store: store}) do
    case store do
      :file ->
        @default_versions_file

      {:file, path} ->
        path

      _ ->
        raise RuntimeError,
          message:
            "trying to get a file in which to store version numbers, but the storage method is #{inspect(store)}"
    end
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

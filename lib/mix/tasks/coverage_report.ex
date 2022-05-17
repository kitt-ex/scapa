defmodule Mix.Tasks.CoverageReport do
  @moduledoc false
  @shortdoc "Generate coverage report"

  use Mix.Task
  alias LcovEx.MixFileHelper

  @doc false
  def run(args) do
    path = Enum.at(args, 0) || File.cwd!()
    mix_path = "#{path}/mix.exs" |> String.replace("//", "/")
    MixFileHelper.backup(mix_path)

    ignore_paths = File.read!("coveralls.json") |> Jason.decode!() |> Map.get("skip_files")

    try do
      config = [
        test_coverage: [
          tool: LcovEx,
          ignore_paths: ignore_paths
        ]
      ]

      MixFileHelper.update_project_config(mix_path, config)
      System.cmd("mix", ["test", "--cover"], cd: path, into: IO.stream(:stdio, :line))
    after
      MixFileHelper.recover(mix_path)
    end
  end
end

defmodule Mix.Tasks.CoverageReport do
  use Mix.Task
  alias LcovEx.MixFileHelper

  @shortdoc "Generate coverage report"
  @moduledoc @shortdoc

  @doc false
  def run(args) do
    path = Enum.at(args, 0) || File.cwd!()
    mix_path = "#{path}/mix.exs" |> String.replace("//", "/")
    MixFileHelper.backup(mix_path)

    try do
      config = [
        test_coverage: [
          tool: LcovEx,
          ignore_paths: ["test/", "lib/scapa/mix/tasks/coverage_report.ex"]
        ]
      ]

      MixFileHelper.update_project_config(mix_path, config)
      System.cmd("mix", ["test", "--cover"], cd: path, into: IO.stream(:stdio, :line))
    after
      MixFileHelper.recover(mix_path)
    end
  end
end

defmodule Scapa.VersionsFileSyncTest do
  use ExUnit.Case, async: true

  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.SyncService
  alias Scapa.SyncBackends.VersionsFileSync

  @file_path "versions.exs"

  describe "sync_steps/2" do
    test "returns the needed inserts for missing versions" do
      source_file = %SourceFile{
        documented_functions: [
          %FunctionDefinition{signature: {Module, :a, 1, "a(b)"}, position: {4, 3}},
          %FunctionDefinition{signature: {Module, :b, 2, "a(c, d)"}, position: {6, 3}}
        ]
      }

      sync = %VersionsFileSync{
        versions: %{}, # simulates versions file empty
        file_path: @file_path
      }

      assert %VersionsFileSync{
               changeset: [
                 {:insert, "versions.exs", {{Module, :a, 1}, "NjEyMDM5NTc"},
                  [
                    origin: %Scapa.FunctionDefinition{
                      signature: {Module, :a, 1, "a(b)"}
                    }
                  ]},
                 {:insert, "versions.exs", {{Module, :b, 2}, "NzQ1OTc1NDQ"},
                  [
                    origin: %Scapa.FunctionDefinition{
                      signature: {Module, :b, 2, "a(c, d)"}
                    }
                  ]}
               ]
             } = SyncService.sync_steps(sync, source_file)
    end

    test "returns the needed updates for missing versions" do
      source_file = %SourceFile{
        documented_functions: [
          %FunctionDefinition{
            signature: {Module, :a, 1, "a(b)"}
          },
          %FunctionDefinition{
            signature: {Module, :b, 2, "a(c, d)"}
          }
        ]
      }

      sync = %VersionsFileSync{
        versions: %{{Module, :a, 1} => "abcd", {Module, :b, 2} => "efgh"},
        file_path: @file_path
      }

      assert %VersionsFileSync{
               changeset: [
                 {:update, "versions.exs", {{Module, :a, 1}, "NjEyMDM5NTc"},
                  [
                    origin: %Scapa.FunctionDefinition{
                      signature: {Module, :a, 1, "a(b)"}
                    }
                  ]},
                 {:update, "versions.exs", {{Module, :b, 2}, "NzQ1OTc1NDQ"},
                  [
                    origin: %Scapa.FunctionDefinition{
                      signature: {Module, :b, 2, "a(c, d)"}
                    }
                  ]}
               ]
             } = SyncService.sync_steps(sync, source_file)
    end

    test "does not return functions that are already in sync" do
      source_file = %SourceFile{
        documented_functions: [
          %FunctionDefinition{signature: {Module, :a, 1, "a(b)"}}
        ]
      }

      sync = %VersionsFileSync{versions: %{{Module, :a, 1} => "NjEyMDM5NTc"}}

      assert %VersionsFileSync{changeset: []} = SyncService.sync_steps(sync, source_file)
    end
  end

  describe "apply_changeset/1" do
    test "applies different changes across source files correclty" do
      sync = %VersionsFileSync{
        file_path: @file_path,
        versions: %{
          {Module, :fun_a} => "fun_a",
          {Module, :fun_b} => "fun_b"
        },
        changeset: [
          {:insert, @file_path, {{Module, :fun1}, "fun1"}, []},
          {:insert, @file_path, {{Module, :fun2}, "fun2"}, []},
          {:update, @file_path, {{Module, :fun_a}, "updated_fun_a"}, []},
          {:insert, @file_path, {{Module, :fun3}, "fun3"}, []},
          {:update, @file_path, {{Module, :fun_b}, "updated_fun_b"}, []},
          {:insert, @file_path, {{Module, :fun4}, "fun4"}, []}
        ]
      }

      assert [
               %Scapa.SourceFile{
                 contents: [
                   "%{",
                   ~s(  {Module, :fun1} => "fun1",),
                   ~s(  {Module, :fun2} => "fun2",),
                   ~s(  {Module, :fun3} => "fun3",),
                   ~s(  {Module, :fun4} => "fun4",),
                   ~s(  {Module, :fun_a} => "updated_fun_a",),
                   ~s(  {Module, :fun_b} => "updated_fun_b"),
                   "}",
                   "\n"
                 ],
                 path: @file_path
               }
             ] = SyncService.apply_changeset(sync)
    end
  end
end

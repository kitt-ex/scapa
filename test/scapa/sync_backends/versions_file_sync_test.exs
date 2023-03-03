defmodule Scapa.VersionsFileSyncTest do
  use ExUnit.Case, async: true

  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.SyncService
  alias Scapa.SyncBackends.VersionsFileSync

  @file_path "versions.exs"

  describe "new/1" do
    test "returns the contents of the versions file as a map" do
      assert %VersionsFileSync{
               changeset: [],
               file_path: "test/support/version_files/versions.exs",
               versions: %{
                 {Scapa.ModuleWithDoc, :multiple_arities, 2} => "outdated",
                 {Scapa.ModuleWithDoc, :public_with_version, 0} => "Mjc5NTIzNTE"
               }
             } =
               VersionsFileSync.new(%Scapa.Config{
                 store: {:file, "test/support/version_files/versions.exs"}
               })
    end

    test "returns an empty map when the file is empty" do
      assert %Scapa.SyncBackends.VersionsFileSync{
               changeset: [],
               file_path: "test/support/version_files/versions_empty.exs",
               versions: %{}
             } =
               VersionsFileSync.new(%Scapa.Config{
                 store: {:file, "test/support/version_files/versions_empty.exs"}
               })
    end

    test "raises an error when the content is not a map" do
      assert_raise ArgumentError,
                   ~s(Expected "test/support/version_files/not_a_map.exs" to return a map, got: [%{}]),
                   fn ->
                     VersionsFileSync.new(%Scapa.Config{
                       store: {:file, "test/support/version_files/not_a_map.exs"}
                     })
                   end
    end

    test "raises an error when the file does not exist" do
      assert_raise RuntimeError,
                   "trying to read versions file but test/support/version_files/not_there.exs does not exist",
                   fn ->
                     VersionsFileSync.new(%Scapa.Config{
                       store: {:file, "test/support/version_files/not_there.exs"}
                     })
                   end
    end
  end

  describe "sync_steps/2" do
    test "returns the needed inserts for missing versions" do
      source_file = %SourceFile{
        documented_functions: [
          %FunctionDefinition{signature: {Module, :a, 1, "a(b)"}, position: {4, 3}},
          %FunctionDefinition{signature: {Module, :b, 2, "a(c, d)"}, position: {6, 3}}
        ]
      }

      sync = %VersionsFileSync{
        # simulates versions file empty
        versions: %{},
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

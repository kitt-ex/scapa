defmodule Scapa.TagsSyncTest do
  use ExUnit.Case, async: true

  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.SyncBackends.TagsSync
  alias Scapa.SyncService

  describe "new/1" do
    test "returns the calculated versions for the source files" do
      source_file = %SourceFile{
        documented_functions: [
          %FunctionDefinition{
            version: "old_abcd",
            signature: {Module, :a, 1, "a(b)"}
          },
          %FunctionDefinition{
            version: "old_efgh",
            signature: {Module, :b, 2, "a(c, d)"}
          }
        ]
      }

      assert %TagsSync{
               changeset: [],
               versions: %{
                 {Module, :a, 1, "a(b)"} => "NjEyMDM5NTc",
                 {Module, :b, 2, "a(c, d)"} => "NzQ1OTc1NDQ"
               }
             } = TagsSync.new([source_file])
    end
  end

  describe "sync_steps/2" do
    test "returns the needed inserts for missing versions" do
      source_file = %SourceFile{
        documented_functions: [
          %FunctionDefinition{version: nil, signature: {Module, :a, 1, "a(b)"}, position: {4, 3}},
          %FunctionDefinition{
            version: nil,
            signature: {Module, :b, 2, "a(c, d)"},
            position: {6, 3}
          }
        ]
      }

      sync = %TagsSync{
        versions: %{{Module, :a, 1, "a(b)"} => "abcd", {Module, :b, 2, "a(c, d)"} => "efgh"}
      }

      assert %TagsSync{
               changeset: [
                 {:insert, {%Scapa.SourceFile{}, 3}, ~s(  @doc version: "abcd"),
                  [
                    origin: %Scapa.FunctionDefinition{
                      signature: {Module, :a, 1, "a(b)"}
                    }
                  ]},
                 {:insert, {%Scapa.SourceFile{}, 5}, ~s(  @doc version: "efgh"),
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
            version: "old_abcd",
            signature: {Module, :a, 1, "a(b)"}
          },
          %FunctionDefinition{
            version: "old_efgh",
            signature: {Module, :b, 2, "a(c, d)"}
          }
        ],
        contents: [
          ~s(  @doc "old_abcd"),
          "  def a(b), do: b",
          ~s(  @doc "old_efgh"),
          "  def a(c, d), do: c + d"
        ]
      }

      sync = %TagsSync{
        versions: %{{Module, :a, 1, "a(b)"} => "abcd", {Module, :b, 2, "a(c, d)"} => "efgh"}
      }

      assert %TagsSync{
               changeset: [
                 {:update, {%Scapa.SourceFile{}, 0}, ~s(  @doc "abcd"),
                  [
                    origin: %Scapa.FunctionDefinition{
                      signature: {Module, :a, 1, "a(b)"}
                    }
                  ]},
                 {:update, {%Scapa.SourceFile{}, 2}, ~s(  @doc "efgh"),
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
          %FunctionDefinition{version: "abcd", signature: {Module, :a, 1, "a(b)"}}
        ]
      }

      sync = %TagsSync{versions: %{{Module, :a, 1, "a(b)"} => "abcd"}}

      assert %TagsSync{changeset: []} = SyncService.sync_steps(sync, source_file)
    end
  end

  describe "apply_changeset/1" do
    test "applies different changes across source files correclty" do
      first = %SourceFile{contents: ~w(a b c d e)}
      second = %SourceFile{contents: ~w(x y z)}

      sync = %TagsSync{
        changeset: [
          {:insert, {first, 2}, "after_b", []},
          {:insert, {second, 0}, "beginning", []},
          {:update, {second, 2}, "new_z", []},
          {:insert, {first, 4}, "after_d", []},
          {:update, {first, 3}, "new_d", []},
          {:insert, {second, 1}, "after_x", []}
        ]
      }

      assert [
               %Scapa.SourceFile{contents: ~w(a b after_b c new_d after_d e)},
               %Scapa.SourceFile{contents: ~w(beginning x after_x y new_z)}
             ] = SyncService.apply_changeset(sync)
    end
  end
end

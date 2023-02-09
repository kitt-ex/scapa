defmodule Scapa.SyncServiceTest do
  use ExUnit.Case, async: true

  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile
  alias Scapa.SyncService

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

      versions = %{{Module, :a, 1, "a(b)"} => "abcd", {Module, :b, 2, "a(c, d)"} => "efgh"}

      assert [
               {:insert, {%Scapa.SourceFile{}, 3}, ~s(  @doc version: "abcd"),
                [
                  origin: %Scapa.FunctionDefinition{
                    signature: {Module, :a, 1, "a(b)"},
                  }
                ]},
               {:insert, {%Scapa.SourceFile{}, 5}, ~s(  @doc version: "efgh"),
                [
                  origin: %Scapa.FunctionDefinition{
                    signature: {Module, :b, 2, "a(c, d)"},
                  }
                ]}
             ] = SyncService.sync_steps(source_file, versions)
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

      versions = %{{Module, :a, 1, "a(b)"} => "abcd", {Module, :b, 2, "a(c, d)"} => "efgh"}

      assert [
               {:update, {%Scapa.SourceFile{}, 0}, ~s(  @doc "abcd"),
                [
                  origin: %Scapa.FunctionDefinition{
                    signature: {Module, :a, 1, "a(b)"},
                  }
                ]},
               {:update, {%Scapa.SourceFile{}, 2}, ~s(  @doc "efgh"),
                [
                  origin: %Scapa.FunctionDefinition{
                    signature: {Module, :b, 2, "a(c, d)"},
                  }
                ]}
             ] = SyncService.sync_steps(source_file, versions)
    end

    test "does not return functions that are already in sync" do
      source_file = %SourceFile{
        documented_functions: [
          %FunctionDefinition{version: "abcd", signature: {Module, :a, 1, "a(b)"}},
        ]
      }

      versions = %{{Module, :a, 1, "a(b)"} => "abcd"}

      assert [] = SyncService.sync_steps(source_file, versions)
    end
  end

  describe "apply_changeset/1" do
    test "applies different changes across source files correclty" do
      first = %SourceFile{contents: ~w(a b c d e)}
      second = %SourceFile{contents: ~w(x y z)}

      changeset = [
        {:insert, {first, 2}, "after_b", []},
        {:insert, {second, 0}, "beginning", []},
        {:update, {second, 2}, "new_z", []},
        {:insert, {first, 4}, "after_d", []},
        {:update, {first, 3}, "new_d", []},
        {:insert, {second, 1}, "after_x", []},
      ]

      assert [
        %Scapa.SourceFile{contents: ~w(a b after_b c new_d after_d e)},
        %Scapa.SourceFile{contents: ~w(beginning x after_x y new_z)}
      ] = SyncService.apply_changeset(changeset)
    end
  end
end

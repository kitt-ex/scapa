defmodule Scapa.SourceFileTest do
  use ExUnit.Case, async: true
  doctest Scapa.SourceFile

  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile

  describe "changes?/1" do
    test "returns true when there are changes" do
      assert SourceFile.changes?(%SourceFile{
               changeset: MapSet.new([{:insert, 2, "something", []}])
             })
    end

    test "returns false when there are no changes" do
      refute SourceFile.changes?(%SourceFile{changeset: MapSet.new()})
    end
  end

  describe "get_chunk/2" do
    test "returns a chung of the contents" do
      assert ["abc", "xyz"] =
               SourceFile.get_chunk(%SourceFile{contents: ["123", "abc", "xyz", "789"]},
                 line_number: 1,
                 lines: 2
               )
    end
  end

  describe "writtable_contents/1" do
    test "returns the contents as a concatenated string" do
      assert ~s{123\nabc\nxyz\n789} =
               SourceFile.writtable_contents(%SourceFile{contents: ["123", "abc", "xyz", "789"]})
    end
  end

  describe "load_from_path/1" do
    @file_path "test/support/module_with_hidden_doc.ex"

    test "returns a source path struct" do
      assert {:ok, %Scapa.SourceFile{}} = SourceFile.load_from_path(@file_path)
    end

    test "loads all the content as single lines" do
      {:ok, %Scapa.SourceFile{contents: contents}} = SourceFile.load_from_path(@file_path)

      assert [
               "defmodule Scapa.ModuleWithHiddenDoc do",
               "  @moduledoc false",
               "",
               "  @doc \"Public with doc\"",
               "  def public_with_doc, do: nil",
               "end",
               ""
             ] = contents
    end

    test "loads all documented functions" do
      {:ok, %Scapa.SourceFile{documented_functions: documented_functions}} =
        SourceFile.load_from_path(@file_path)

      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithHiddenDoc, :public_with_doc, 0, "public_with_doc()"},
                 position: {5, 3},
                 version: nil
               }
             ] = documented_functions
    end

    test "returns an error when something goes wrong" do
      assert {:error, :enoent} = SourceFile.load_from_path("does/not/exist.ex")
    end
  end

  describe "generate_doc_version_changes/1" do
    @file_path "test/support/module_with_doc.ex"

    test "loads the chagngeset with the changes to be made" do
      {:ok, source_file} = SourceFile.load_from_path(@file_path)

      %SourceFile{changeset: changeset} = SourceFile.generate_doc_version_changes(source_file)

      assert [
               {:insert, 7, "  @doc version: \"NzUzMzUyMjQ\"", _},
               {:insert, 14, "  @doc version: \"MzA2ODU5NTI\"", _},
               {:insert, 18, "  @doc version: \"MTE5Mjc1OTkw\"", _},
               {:insert, 26, "  @doc version: \"MTEwNjA4MzA\"", _},
               {:insert, 29, "  @doc version: \"NzYxNDM1MDc\"", _},
               {:insert, 32, "  @doc version: \"NTgwNDA2NzY\"", _},
               {:insert, 35, "  @doc version: \"NDA5ODYzMDA\"", _},
               {:insert, 38, "  @doc version: \"ODQ2NTA0MTM\"", _},
               {:update, 10, "  @doc version: \"Mjc5NTIzNTE\"", _}
             ] = Enum.to_list(changeset)
    end
  end

  describe "apply_changeset/1" do
    @file_path "test/support/module_with_hidden_doc.ex"

    test "returns a new source file with the changes applied to the content" do
      {:ok, source_file} = SourceFile.load_from_path(@file_path)
      source_file = SourceFile.generate_doc_version_changes(source_file)

      %Scapa.SourceFile{contents: contents, changeset: changeset} =
        SourceFile.apply_changeset(source_file)

      assert [] = Enum.to_list(changeset)

      assert [
               "defmodule Scapa.ModuleWithHiddenDoc do",
               "  @moduledoc false",
               "",
               "  @doc \"Public with doc\"",
               "  @doc version: \"Njc0NzQyOTY\"",
               "  def public_with_doc, do: nil",
               "end",
               ""
             ] = contents
    end
  end
end

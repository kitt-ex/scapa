defmodule Scapa.SourceFileTest do
  use ExUnit.Case, async: true
  doctest Scapa.SourceFile

  alias Scapa.FunctionDefinition
  alias Scapa.SourceFile

  describe "get_chunk/2" do
    test "returns a chung of the contents" do
      assert ["abc", "xyz"] =
               SourceFile.get_chunk(%SourceFile{contents: ["123", "abc", "xyz", "789"]},
                 line_number: 1,
                 lines: 2
               )
    end
  end

  describe "writtable_conwriteable_contentstents/1" do
    test "returns the contents as a concatenated string" do
      assert ~s{123\nabc\nxyz\n789} =
               SourceFile.writeable_contents(%SourceFile{contents: ["123", "abc", "xyz", "789"]})
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
end

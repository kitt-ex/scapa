defmodule Scapa.CodeTest do
  use ExUnit.Case, async: true

  alias Scapa.Code
  alias Scapa.FunctionDefinition

  describe "functions_with_doc/1" do
    test "returns functions with docs" do
      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithDoc, :public_with_doc, 0, "public_with_doc()"}
               }
             ] =
               function_docs(
                 Code.functions_with_doc([{:module, Scapa.ModuleWithDoc}]),
                 :public_with_doc
               )
    end

    test "adds the version if present" do
      assert [
               %FunctionDefinition{
                 signature:
                   {Scapa.ModuleWithDoc, :public_with_version, 0, "public_with_version()"},
                 version: "abc"
               }
             ] =
               function_docs(
                 Code.functions_with_doc([{:module, Scapa.ModuleWithDoc}]),
                 :public_with_version
               )
    end

    test "returns the correct doc for functions with multiple definitions" do
      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithDoc, :multiple_def, 1, "multiple_def(arg1)"}
               }
             ] =
               function_docs(
                 Code.functions_with_doc([{:module, Scapa.ModuleWithDoc}]),
                 :multiple_def
               )
    end

    test "returns the correct doc for functions with multiple definitions and default parameters" do
      assert [
               %FunctionDefinition{
                 signature:
                   {Scapa.ModuleWithDoc, :multiple_def_with_default, 1,
                    ~S{multiple_def_with_default(num \\ 42)}}
               }
             ] =
               function_docs(
                 Code.functions_with_doc([{:module, Scapa.ModuleWithDoc}]),
                 :multiple_def_with_default
               )
    end

    test "returns functions from hidden doc modules" do
      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithHiddenDoc, :public_with_doc, 0, "public_with_doc()"}
               }
             ] =
               function_docs(
                 Code.functions_with_doc([{:module, Scapa.ModuleWithHiddenDoc}]),
                 :public_with_doc
               )
    end

    test "does not include functions without doc" do
      docs = Code.functions_with_doc([{:module, Scapa.ModuleWithDoc}])

      assert [] = function_docs(docs, :public_no_doc)
    end

    test "does not include private functions" do
      docs = Code.functions_with_doc([{:module, Scapa.ModuleWithDoc}])

      assert [] = function_docs(docs, :private_fun)
    end
  end

  describe "upsert_doc_version/3" do
    test "updates the version when it exists", %{module_source: module_source} do
      function_definition = %FunctionDefinition{
        signature: {Scapa.ModuleWithDoc, :public_with_version, 0, "public_with_version()"},
        version: "abc"
      }

      output = Code.upsert_doc_version(module_source, function_definition, "new_version")

      assert String.contains?(output, ~s(@doc version: "new_version"))
      refute String.contains?(output, ~s(@doc version: "abc"))
    end

    test "does not add version tags when updating", %{module_source: module_source} do
      function_definition = %FunctionDefinition{
        signature: {Scapa.ModuleWithDoc, :public_with_version, 0, "public_with_version()"},
        version: "abc"
      }

      output = Code.upsert_doc_version(module_source, function_definition, "new_version")

      assert version_tags_count(output) == version_tags_count(module_source)
    end

    test "adds the the version when it does not exist", %{module_source: module_source} do
      function_definition = %FunctionDefinition{
        signature: {Scapa.ModuleWithDoc, :public_with_doc, 0, "public_with_doc()"}
      }

      output =
        Code.upsert_doc_version(module_source, function_definition, "public_function_version")

      function_fragment = cut_source(output, 6..8)

      assert function_fragment ==
               ~s(  @doc "Public with doc"\n  @doc version: "public_function_version"\n  def public_with_doc, do: nil)
    end

    test "does not add multiple version tags when inserting", %{module_source: module_source} do
      function_definition = %FunctionDefinition{
        signature: {Scapa.ModuleWithDoc, :public_with_doc, 0, "public_with_doc()"}
      }

      output =
        Code.upsert_doc_version(module_source, function_definition, "public_function_version")

      assert version_tags_count(output) == version_tags_count(module_source) + 1
    end
  end

  describe "doc_location/1" do
    test "returns the line number for the @doc when present" do
      assert 7 =
               Code.doc_location(%FunctionDefinition{
                 signature: {Scapa.ModuleWithDoc, :public_with_doc, 0, "public_with_doc()"}
               })
    end

    test "returns the function line when the @doc tag is not present" do
      assert 24 =
               Code.doc_location(%FunctionDefinition{
                 signature: {Scapa.ModuleWithDoc, :public_no_doc, 0, "public_no_doc()"}
               })
    end
  end

  setup_all do
    module_source = File.read!(Path.absname("../support/module_with_doc.ex", __DIR__))

    %{module_source: module_source}
  end

  defp function_docs(docs, function_name) do
    Enum.filter(docs, fn %FunctionDefinition{signature: {_, name, _, _}} ->
      name == function_name
    end)
  end

  defp cut_source(source, range) do
    source
    |> String.split("\n")
    |> Enum.slice(range)
    |> Enum.join("\n")
  end

  defp version_tags_count(source) do
    Enum.count(Regex.scan(~r/version: ".*"/, source))
  end
end

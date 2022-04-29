defmodule Scapa.DocumentedFunctionsFinderTest do
  use ExUnit.Case, async: true
  alias Scapa.DocumentedFunctionsFinder
  alias Scapa.FunctionDefinition

  describe "find_in/1" do
    test "returns functions with docs" do
      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithDoc, :public_with_doc, 0, "public_with_doc()"}
               }
             ] =
               function_docs(
                 DocumentedFunctionsFinder.find_in([{:module, Scapa.ModuleWithDoc}]),
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
                 DocumentedFunctionsFinder.find_in([{:module, Scapa.ModuleWithDoc}]),
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
                 DocumentedFunctionsFinder.find_in([{:module, Scapa.ModuleWithDoc}]),
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
                 DocumentedFunctionsFinder.find_in([{:module, Scapa.ModuleWithDoc}]),
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
                 DocumentedFunctionsFinder.find_in([{:module, Scapa.ModuleWithHiddenDoc}]),
                 :public_with_doc
               )
    end

    test "does not include functions without doc" do
      docs = DocumentedFunctionsFinder.find_in([{:module, Scapa.ModuleWithDoc}])

      assert [] = function_docs(docs, :public_no_doc)
    end

    test "does not include private functions" do
      docs = DocumentedFunctionsFinder.find_in([{:module, Scapa.ModuleWithDoc}])

      assert [] = function_docs(docs, :private_fun)
    end
  end

  defp function_docs(docs, function_name) do
    Enum.filter(docs, fn %FunctionDefinition{signature: {_, name, _, _}} ->
      name == function_name
    end)
  end
end

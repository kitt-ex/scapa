defmodule Scapa.CodeTest do
  use ExUnit.Case, async: true
  doctest Scapa.Code

  alias Scapa.Code
  alias Scapa.FunctionDefinition

  describe "functions_with_doc/1" do
    test "returns functions with docs", %{Scapa.ModuleWithDoc => module_source} do
      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithDoc, :public_with_doc, 0, "public_with_doc()"}
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source}),
                 :public_with_doc
               )
    end

    test "adds the version if present", %{Scapa.ModuleWithDoc => module_source} do
      assert [
               %FunctionDefinition{
                 signature:
                   {Scapa.ModuleWithDoc, :public_with_version, 0, "public_with_version()"},
                 version: "abc"
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source}),
                 :public_with_version
               )
    end

    test "returns the correct doc for functions with multiple definitions", %{
      Scapa.ModuleWithDoc => module_source
    } do
      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithDoc, :multiple_def, 1, "multiple_def(arg1)"}
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source}),
                 :multiple_def
               )
    end

    test "returns the correct doc for functions with multiple definitions and default parameters",
         %{Scapa.ModuleWithDoc => module_source} do
      assert [
               %FunctionDefinition{
                 signature:
                   {Scapa.ModuleWithDoc, :multiple_def_with_default, 1,
                    ~S{multiple_def_with_default(num \\ 42)}}
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source}),
                 :multiple_def_with_default
               )
    end

    test "returns functions from hidden doc modules", %{
      Scapa.ModuleWithHiddenDoc => module_source
    } do
      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithHiddenDoc, :public_with_doc, 0, "public_with_doc()"}
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithHiddenDoc, module_source}),
                 :public_with_doc
               )
    end

    test "does not include functions without doc", %{Scapa.ModuleWithDoc => module_source} do
      docs = Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source})

      assert [] = function_docs(docs, :public_no_doc)
    end

    test "does not include private functions", %{Scapa.ModuleWithDoc => module_source} do
      docs = Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source})

      assert [] = function_docs(docs, :private_fun)
    end
  end

  describe "upsert_doc_version/3" do
    test "updates the version when it exists", %{Scapa.ModuleWithDoc => module_source} do
      function_definition = %FunctionDefinition{
        signature: {Scapa.ModuleWithDoc, :public_with_version, 0, "public_with_version()"},
        version: "abc"
      }

      output = Code.upsert_doc_version(module_source, function_definition, "new_version")

      assert String.contains?(output, ~s(@doc version: "new_version"))
      refute String.contains?(output, ~s(@doc version: "abc"))
    end

    test "does not add version tags when updating", %{Scapa.ModuleWithDoc => module_source} do
      function_definition = %FunctionDefinition{
        signature: {Scapa.ModuleWithDoc, :public_with_version, 0, "public_with_version()"},
        version: "abc"
      }

      output = Code.upsert_doc_version(module_source, function_definition, "new_version")

      assert version_tags_count(output) == version_tags_count(module_source)
    end

    test "adds the the version when it does not exist", %{Scapa.ModuleWithDoc => module_source} do
      function_definition = %FunctionDefinition{
        signature: {Scapa.ModuleWithDoc, :public_with_doc, 0, "public_with_doc()"},
        position: {8, 3}
      }

      output =
        Code.upsert_doc_version(module_source, function_definition, "public_function_version")

      function_fragment = cut_source(output, 6..8)

      assert function_fragment ==
               ~s(  @doc "Public with doc"\n  @doc version: "public_function_version"\n  def public_with_doc, do: nil)
    end

    test "does not add multiple version tags when inserting", %{
      Scapa.ModuleWithDoc => module_source
    } do
      function_definition = %FunctionDefinition{
        signature: {Scapa.ModuleWithDoc, :public_with_doc, 0, "public_with_doc()"},
        position: {8, 3}
      }

      output =
        Code.upsert_doc_version(module_source, function_definition, "public_function_version")

      assert version_tags_count(output) == version_tags_count(module_source) + 1
    end
  end

  describe "defined_modules/1" do
    test "returns single modules" do
      ast =
        quote do
          defmodule Scapa, do: nil
        end

      assert [Scapa] = Code.defined_modules(ast)
    end

    test "returns nested modules" do
      ast =
        quote do
          defmodule Scapa do
            defmodule Scapa.Insider, do: nil
          end
        end

      assert [Scapa.Insider, Scapa] = Code.defined_modules(ast)
    end

    test "returns sibling modules" do
      ast =
        quote do
          defmodule Scapa, do: nil
          defmodule Scapa.Sibling, do: nil
        end

      assert [Scapa.Sibling, Scapa] = Code.defined_modules(ast)
    end
  end

  setup_all do
    module_with_doc = File.read!(Path.absname("../support/module_with_doc.ex", __DIR__))

    module_with_hidden_doc =
      File.read!(Path.absname("../support/module_with_hidden_doc.ex", __DIR__))

    %{
      Scapa.ModuleWithDoc => module_with_doc,
      Scapa.ModuleWithHiddenDoc => module_with_hidden_doc
    }
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

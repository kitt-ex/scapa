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

    test "returns functions with multiple arities", %{Scapa.ModuleWithDoc => module_source} do
      assert [
               %FunctionDefinition{
                 signature: {Scapa.ModuleWithDoc, :multiple_arities, 1, "multiple_arities(a)"},
                 position: {27, 3},
                 version: nil
               },
               %FunctionDefinition{
                 position: {30, 3},
                 signature: {Scapa.ModuleWithDoc, :multiple_arities, 2, "multiple_arities(a, b)"},
                 version: nil
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source}),
                 :multiple_arities
               )
    end

    test "returns functions with guards", %{Scapa.ModuleWithDoc => module_source} do
      assert [
               %FunctionDefinition{
                 position: {33, 3},
                 signature: {Scapa.ModuleWithDoc, :public_with_guard, 1, "public_with_guard(a)"},
                 version: nil
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source}),
                 :public_with_guard
               )
    end

    test "returns macros", %{Scapa.ModuleWithDoc => module_source} do
      assert [
               %FunctionDefinition{
                 position: {36, 3},
                 signature: {Scapa.ModuleWithDoc, :macro, 3, "macro(a, b, c)"},
                 version: nil
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source}),
                 :macro
               )
    end

    test "returns macros with guards", %{Scapa.ModuleWithDoc => module_source} do
      assert [
               %FunctionDefinition{
                 position: {39, 3},
                 signature: {Scapa.ModuleWithDoc, :__using__, 1, "__using__(which)"},
                 version: nil
               }
             ] =
               function_docs(
                 Code.functions_with_doc({:module, Scapa.ModuleWithDoc, module_source}),
                 :__using__
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

    test "does not include type docs", %{Scapa.ModuleWithTypedoc => module_source} do
      docs = Code.functions_with_doc({:module, Scapa.ModuleWithTypedoc, module_source})

      assert [] = function_docs(docs, :num)
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

    test "returns nested modules and sibling modules" do
      ast = Elixir.Code.string_to_quoted!(File.read!("test/support/nested_module.ex"))

      assert [
               NestedModule,
               NestedModule.Sibling,
               NestedModule.Level1.AndSomethingElse,
               NestedModule.Level1.AndSomethingElse.Level2
             ] = Code.defined_modules(ast)
    end
  end

  setup_all do
    module_with_doc = File.read!(Path.absname("../support/module_with_doc.ex", __DIR__))

    module_with_typedoc = File.read!(Path.absname("../support/module_with_typedoc.ex", __DIR__))

    module_with_hidden_doc =
      File.read!(Path.absname("../support/module_with_hidden_doc.ex", __DIR__))

    %{
      Scapa.ModuleWithDoc => module_with_doc,
      Scapa.ModuleWithTypedoc => module_with_typedoc,
      Scapa.ModuleWithHiddenDoc => module_with_hidden_doc
    }
  end

  defp function_docs(docs, function_name) do
    Enum.filter(docs, fn %FunctionDefinition{signature: {_, name, _, _}} ->
      name == function_name
    end)
  end
end

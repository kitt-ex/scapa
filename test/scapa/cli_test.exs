defmodule Scapa.CLITest do
  use ExUnit.Case, async: true

  alias Scapa.CLI
  alias Scapa.Config

  @config %Config{include: ["test/support/*.ex"]}

  describe "generate_versions/1" do
    test "returns the file location and new source code wih versions" do
      results = CLI.generate_versions(@config)
      module_with_doc = find_file_result(results, "/support/module_with_doc.ex")
      module_with_hidden_doc = find_file_result(results, "/support/module_with_hidden_doc.ex")

      assert elem(module_with_doc, 1) == """
             defmodule Scapa.ModuleWithDoc do
               @moduledoc \"""
               Test module used to test the returned function definitions and
               the corresponding version.
               \"""

               @doc "Public with doc"
               @doc version: "75335224"
               def public_with_doc, do: nil

               @doc "Public with version"
               @doc version: "27952351"
               def public_with_version, do: private_fun()

               @doc "Multiple def"
               @doc version: "30685952"
               def multiple_def(1), do: 2
               def multiple_def("2"), do: 4

               @doc "Multiple def with default"
               @doc version: "119275990"
               def multiple_def_with_default(num \\\\ 42)

               def multiple_def_with_default(1), do: 2
               def multiple_def_with_default(2), do: 4

               def public_no_doc, do: nil

               @doc "Multiple arities 1"
               @doc version: "11060830"
               def multiple_arities(_a), do: nil

               @doc "Multiple arities 2"
               @doc version: "76143507"
               def multiple_arities(_a, _b), do: nil

               @doc "Public with guard"
               @doc version: "58040676"
               def public_with_guard(a) when is_atom(a), do: nil

               @doc "Simple macro"
               @doc version: "40986300"
               defmacro macro(_a, _b, _c), do: nil

               @doc "Macro with guard"
               @doc version: "84650413"
               defmacro __using__(which) when is_atom(which) and not is_nil(which) do
                 apply(__MODULE__, which, [])
               end

               defp private_fun, do: nil
             end
             """

      assert elem(module_with_hidden_doc, 1) == """
             defmodule Scapa.ModuleWithHiddenDoc do
               @moduledoc false

               @doc "Public with doc"
               @doc version: "67474296"
               def public_with_doc, do: nil
             end
             """
    end

    test "returns no_changes if there's no changes to be saved" do
      results = CLI.generate_versions(@config)

      assert {:ok, :no_changes, _full_path} =
               find_file_result(results, "/support/module_with_typedoc.ex")
    end
  end

  describe "generate_versions/2" do
    test "returns verbose data about the changes" do
      results = CLI.generate_versions(@config, _verbose = true)

      {:ok, _, no_changes_file_path} = find_result_by_type(results, :no_changes)

      {:ok, _, _, missing_version_function, missing_version_file_path} =
        find_result_by_type(results, :missing_version)

      {:ok, _, _, outdated_version_function, outdated_version_file_path} =
        find_result_by_type(results, :outdated_version)

      assert no_changes_file_path =~ "module_with_typedoc.ex"
      assert missing_version_file_path =~ "module_with_doc.ex"
      assert missing_version_function =~ "defmacro __using__(which)"
      assert outdated_version_file_path =~ "module_with_doc.ex"
      assert outdated_version_function =~ "def public_with_version, do:"
    end
  end

  defp find_file_result(results, file_name) do
    Enum.find(results, fn {_, _, path} -> String.ends_with?(path, file_name) end)
  end

  defp find_result_by_type(results, type) do
    Enum.find(results, fn r ->
      case r do
        {_, t, _} -> t == type
        {_, t, _, _, _} -> t == type
      end
    end)
  end
end

defmodule Scapa.CLITest do
  use ExUnit.Case, async: true

  alias Scapa.CLI

  describe "generate_versions/1" do
    test "returns the file location and new source code wih versions" do
      [module_with_doc, module_with_hidden_doc] = CLI.generate_versions("test/support/*.ex")

      assert String.ends_with?(elem(module_with_doc, 0), "/support/module_with_doc.ex")

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
               def public_with_version, do: nil

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

               defp private_fun, do: nil
             end
             """

      assert String.ends_with?(
               elem(module_with_hidden_doc, 0),
               "/support/module_with_hidden_doc.ex"
             )

      assert elem(module_with_hidden_doc, 1) == """
             defmodule Scapa.ModuleWithHiddenDoc do
               @moduledoc false

               @doc "Public with doc"
               @doc version: "67474296"
               def public_with_doc, do: nil
             end
             """
    end
  end
end

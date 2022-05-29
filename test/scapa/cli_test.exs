defmodule Scapa.CLITest do
  use ExUnit.Case, async: true

  alias Scapa.CLI
  alias Scapa.Config
  alias Scapa.SourceFile

  @config %Config{include: ["test/support/*.ex"]}

  describe "generate_versions/1" do
    test "returns the file location and new source code wih versions" do
      {:ok, source_files} = CLI.generate_versions(@config)
      module_with_doc = find_file_source(source_files, "/support/module_with_doc.ex")

      module_with_hidden_doc =
        find_file_source(source_files, "/support/module_with_hidden_doc.ex")

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
             ] = Enum.to_list(module_with_doc.changeset)

      assert [
               {:insert, 4, "  @doc version: \"Njc0NzQyOTY\"", _}
             ] = Enum.to_list(module_with_hidden_doc.changeset)
    end

    test "returns an empty list if there's no changes to be saved" do
      {:ok, source_files} = CLI.generate_versions(@config)

      %SourceFile{changeset: changeset} =
        find_file_source(source_files, "/support/module_with_typedoc.ex")

      assert [] = Enum.to_list(changeset)
    end
  end

  describe "check_versions/1" do
    test "returns changes for missing versions" do
      {:ok, results} = CLI.check_versions(@config)

      {_source_file, changes} = find_file_source(results, "/support/module_with_hidden_doc.ex")

      [{:insert, change_origin_function, change_line, current_content, new_content}] = changes

      assert %Scapa.FunctionDefinition{
               position: {5, 3},
               signature: {Scapa.ModuleWithHiddenDoc, :public_with_doc, 0, "public_with_doc()"},
               version: nil
             } = change_origin_function

      assert 4 = change_line

      assert ["  def public_with_doc, do: nil", "end", ""] = current_content
      assert ~s(  @doc version: "Njc0NzQyOTY") = new_content
    end

    test "returns changes for missing functions" do
      {:ok, results} = CLI.check_versions(@config)

      {_source_file, changes} = find_file_source(results, "/support/module_with_doc.ex")

      {:update, change_origin_function, change_line, current_content, new_content} =
        Enum.find(changes, &(elem(&1, 0) == :update))

      assert %Scapa.FunctionDefinition{
               position: {12, 3},
               signature: {Scapa.ModuleWithDoc, :public_with_version, 0, "public_with_version()"},
               version: "abc"
             } = change_origin_function

      assert 10 = change_line

      assert [~s(  @doc version: "abc"), "  def public_with_version, do: private_fun()", ""] =
               current_content

      assert ~s(  @doc version: "Mjc5NTIzNTE") = new_content
    end

    test "returns an empty list when there are no changes" do
      {:ok, results} = CLI.check_versions(@config)

      assert {_source_file, []} = find_file_source(results, "/support/module_with_typedoc.ex")
    end
  end

  defp find_file_source(results, file_name) do
    Enum.find(results, fn
      %SourceFile{path: path} -> String.ends_with?(path, file_name)
      {%SourceFile{path: path}, _updates} -> String.ends_with?(path, file_name)
    end)
  end
end

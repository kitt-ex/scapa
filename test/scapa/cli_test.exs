defmodule Scapa.CLITest do
  use ExUnit.Case, async: true

  alias Scapa.CLI
  alias Scapa.Config
  alias Scapa.SourceFile

  @config %Config{include: ["test/support/*.ex"], store: :tags}

  describe "generate_versions/1" do
    test "returns the file location and new source code wih versions based on the tags" do
      {:ok, source_files} = CLI.generate_versions(@config)
      module_with_doc = find_from_file_source(source_files, "/support/module_with_doc.ex")

      module_with_hidden_doc =
        find_from_file_source(source_files, "/support/module_with_hidden_doc.ex")

      assert [
               {:insert, {%SourceFile{}, 7}, "  @doc version: \"NzUzMzUyMjQ\"", _},
               {:insert, {%SourceFile{}, 14}, "  @doc version: \"MzA2ODU5NTI\"", _},
               {:insert, {%SourceFile{}, 18}, "  @doc version: \"MTE5Mjc1OTkw\"", _},
               {:insert, {%SourceFile{}, 26}, "  @doc version: \"MTEwNjA4MzA\"", _},
               {:insert, {%SourceFile{}, 29}, "  @doc version: \"NzYxNDM1MDc\"", _},
               {:insert, {%SourceFile{}, 32}, "  @doc version: \"NTgwNDA2NzY\"", _},
               {:insert, {%SourceFile{}, 35}, "  @doc version: \"NDA5ODYzMDA\"", _},
               {:insert, {%SourceFile{}, 38}, "  @doc version: \"ODQ2NTA0MTM\"", _},
               {:update, {%SourceFile{}, 10}, "  @doc version: \"Mjc5NTIzNTE\"", _}
             ] = module_with_doc

      assert [
               {:insert, {%SourceFile{}, 4}, "  @doc version: \"Njc0NzQyOTY\"", _}
             ] = module_with_hidden_doc
    end

    @tag :skip
    test "returns the file location and new source code wih versions based on the versions file" do
      {:ok, source_files} =
        CLI.generate_versions(%{
          @config
          | store: {:file, "test/support/version_files/versions.exs"}
        })

      changeset = find_from_file_source(source_files, "/support/module_with_doc.ex")

      assert [
               {:insert, {%SourceFile{}, 7}, "{Scapa.ModuleWithDoc, 1} => \"NzUzMzUyMjQ\"", _},
               {:insert, {%SourceFile{}, 14}, "{Scapa.ModuleWithDoc, 2} => \"MzA2ODU5NTI\"", _},
               {:insert, {%SourceFile{}, 18}, "{Scapa.ModuleWithDoc, 3} => \"MTE5Mjc1OTkw\"", _},
               {:insert, {%SourceFile{}, 26}, "{Scapa.ModuleWithDoc, 4} => \"MTEwNjA4MzA\"", _},
               {:insert, {%SourceFile{}, 29}, "{Scapa.ModuleWithDoc, 5} => \"NzYxNDM1MDc\"", _},
               {:insert, {%SourceFile{}, 32}, "{Scapa.ModuleWithDoc, 6} => \"NTgwNDA2NzY\"", _},
               {:insert, {%SourceFile{}, 35}, "{Scapa.ModuleWithDoc, 7} => \"NDA5ODYzMDA\"", _},
               {:insert, {%SourceFile{}, 38}, "{Scapa.ModuleWithDoc, 8} => \"ODQ2NTA0MTM\"", _},
               {:update, {%SourceFile{}, 10}, "{Scapa.ModuleWithDoc, 9} => \"Mjc5NTIzNTE\"", _}
             ] = Enum.to_list(changeset)
    end

    test "returns an empty list if there's no changes to be saved" do
      {:ok, source_files} = CLI.generate_versions(@config)

      assert [] = find_from_file_source(source_files, "/support/module_with_typedoc.ex")
    end
  end

  describe "check_versions/1" do
    test "returns changes for missing versions" do
      {:ok, results} = CLI.check_versions(@config)

      {_source_file, changes} = find_file_source(results, "/support/module_with_hidden_doc.ex")

      [{:insert, location, new_content, metadata}] = changes

      assert %Scapa.FunctionDefinition{
               position: {5, 3},
               signature: {Scapa.ModuleWithHiddenDoc, :public_with_doc, 0, "public_with_doc()"},
               version: nil
             } = metadata[:origin]

      assert {%SourceFile{}, 4} = location

      assert ~s(  @doc version: "Njc0NzQyOTY") = new_content
    end

    test "returns changes for missing functions" do
      {:ok, results} = CLI.check_versions(@config)

      {_source_file, changes} = find_file_source(results, "/support/module_with_doc.ex")

      {:update, location, new_content, metadata} = Enum.find(changes, &(elem(&1, 0) == :update))

      assert %Scapa.FunctionDefinition{
               position: {12, 3},
               signature: {Scapa.ModuleWithDoc, :public_with_version, 0, "public_with_version()"},
               version: "abc"
             } = metadata[:origin]

      assert {%SourceFile{}, 10} = location

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

  defp find_from_file_source(results, file_name) do
    Enum.filter(results, fn result ->
      {%SourceFile{path: path}, _line_number} = elem(result, 1)

      String.ends_with?(path, file_name)
    end)
    |> Enum.sort()
  end
end

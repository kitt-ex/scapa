defmodule Scapa.VersionStores.FileStoreTest do
  use ExUnit.Case, async: true
  doctest Scapa.VersionStores.FileStore

  alias Scapa.FunctionDefinition
  alias Scapa.VersionsStore
  alias Scapa.VersionStores.FileStore

  describe "new/1" do
    test "returns a file store with the correct versions from a correct versions file" do
      assert %FileStore{versions: %{{Module, :my_fun, 3} => "abc"}} =
               FileStore.new("test/support/version_files/versions.exs")
    end

    test "returns a file store with no versions from an empty versions file" do
      assert %FileStore{versions: %{}} =
               FileStore.new("test/support/version_files/versions_empty.exs")
    end

    test "raises an error when the versions file has the incorrect format" do
      assert_raise ArgumentError,
                   ~s(Expected "test/support/version_files/not_a_map.exs" to return a map, got: [%{}]),
                   fn ->
                     FileStore.new("test/support/version_files/not_a_map.exs")
                   end
    end

    test "raises an error when the versions file does not exist" do
      assert_raise RuntimeError,
                   "trying to read versions file but test/support/version_files/does_not_exist.exs does not exist",
                   fn ->
                     FileStore.new("test/support/version_files/does_not_exist.exs")
                   end
    end
  end

  describe "impl get_version/2" do
    test "returns the value already set in the function version" do
      store = %FileStore{versions: %{{Module, :my_fun, 3} => "abc"}}

      VersionsStore.get_version(store, %FunctionDefinition{
        signature: {Module, :my_fun, 3, "my_fun(a, b, c)"}
      })
    end
  end
end

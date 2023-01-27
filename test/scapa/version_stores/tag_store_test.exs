defmodule Scapa.VersionStores.TagStoreTest do
  use ExUnit.Case, async: true
  doctest Scapa.VersionStores.TagsStore

  alias Scapa.FunctionDefinition
  alias Scapa.VersionsStore
  alias Scapa.VersionStores.TagsStore

  describe "impl get_version/2" do
    test "returns the value already set in the function version" do
      assert "abc" = VersionsStore.get_version(%TagsStore{}, %FunctionDefinition{version: "abc"})
    end
  end
end

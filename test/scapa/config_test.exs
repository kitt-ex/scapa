defmodule Scapa.ConfigTest do
  use ExUnit.Case, async: true

  alias Scapa.Config

  describe "fetch_config/1" do
    test "reads config from a given path" do
      assert %Config{include: ["all/my/files/*.exs"]} =
               Config.fetch_config("test/support/config_files/.scapa.exs")
    end

    test "injects default when the file does not exist" do
      assert %Config{include: ["lib/**/*.ex"]} = Config.fetch_config("does/not-exists/.scapa.exs")
    end

    test "raises an error with extra arguments" do
      assert_raise KeyError,
                   ~s(key :invalid not found in: %Scapa.Config{include: ["all/my/files/*.exs"]}),
                   fn ->
                     Config.fetch_config("test/support/config_files/.scapa_extra_configs.exs")
                   end
    end

    test "raises an error with non-keyword configs" do
      assert_raise ArgumentError,
                   ~s(Expected "test/support/config_files/.scapa_not_keyword.exs" to return a keyword list, got: %{include: "soy/el/mapa/*.ex"}),
                   fn ->
                     Config.fetch_config("test/support/config_files/.scapa_not_keyword.exs")
                   end
    end
  end
end

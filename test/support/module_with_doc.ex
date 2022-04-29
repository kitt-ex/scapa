defmodule Scapa.ModuleWithDoc do
  @moduledoc """
  Test module used to test the returned function definitions and
  the corresponding version.
  """

  @doc "Public with doc"
  def public_with_doc, do: nil

  @doc "Public with version"
  @doc version: "abc"
  def public_with_version, do: nil

  @doc "Multiple def"
  def multiple_def(1), do: 2
  def multiple_def("2"), do: 4

  @doc "Multiple def with default"
  def multiple_def_with_default(num \\ 42)

  def multiple_def_with_default(1), do: 2
  def multiple_def_with_default(2), do: 4

  def public_no_doc, do: nil

  defp private_fun, do: nil
end

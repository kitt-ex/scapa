defmodule Scapa.ModuleWithDoc do
  @moduledoc """
  Test module used to test the returned function definitions and
  the corresponding version.
  """

  @doc "Public with doc"
  def public_with_doc, do: nil

  @doc "Public with version"
  @doc version: "abc"
  def public_with_version, do: private_fun()

  @doc "Multiple def"
  def multiple_def(1), do: 2
  def multiple_def("2"), do: 4

  @doc "Multiple def with default"
  def multiple_def_with_default(num \\ 42)

  def multiple_def_with_default(1), do: 2
  def multiple_def_with_default(2), do: 4

  def public_no_doc, do: nil

  @doc "Multiple arities 1"
  def multiple_arities(_a), do: nil

  @doc "Multiple arities 2"
  def multiple_arities(_a, _b), do: nil

  @doc "Public with guard"
  def public_with_guard(a) when is_atom(a), do: nil

  @doc "Simple macro"
  defmacro macro(_a, _b, _c), do: nil

  @doc "Macro with guard"
  defmacro __using__(which) when is_atom(which) and not is_nil(which) do
    apply(__MODULE__, which, [])
  end

  defp private_fun, do: nil
end

defmodule Scapa.ModuleWithHiddenDoc do
  @moduledoc false

  @doc "Public with doc"
  def public_with_doc, do: nil
end

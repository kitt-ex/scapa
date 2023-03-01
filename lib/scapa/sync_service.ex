defprotocol Scapa.SyncService do
  @moduledoc false
  alias Scapa.SourceFile

  @type function_versions :: %{Scapa.FunctionDefinition.t() => Scapa.FunctionDefinition.version()}
  @type change ::
          {operation(), {SourceFile.t(), SourceFile.line_number()}, SourceFile.content(),
           metadata()}
  @type operation :: :insert | :update
  @typep metadata :: Keyword.t()

  @spec sync_steps(t, SourceFile.t()) :: t
  def sync_steps(sync, source_file)

  @spec apply_changeset(t) :: [SourceFile.t()]
  def apply_changeset(sync)
end

defprotocol Scapa.VersionsStore do
  @spec get_version(t, Scapa.FunctionDefinition.t()) :: Scapa.FunctionDefinition.version()
  def get_version(store, function)
end

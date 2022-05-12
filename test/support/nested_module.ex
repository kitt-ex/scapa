defmodule NestedModule do
  @moduledoc false
  defmodule Level1.AndSomethingElse do
    @moduledoc false
    defmodule Level2 do
      @moduledoc false
      def hi, do: "Howdy!"
    end
  end

  defmodule Sibling, do: @moduledoc(false)
end

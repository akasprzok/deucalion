defmodule Deucalion.HelpLine do
  @type t :: %__MODULE__{
          metric_name: String.t(),
          docstring: String.t()
        }

  defstruct metric_name: nil,
            docstring: nil
end

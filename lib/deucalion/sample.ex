defmodule Deucalion.Sample do
  @type t :: %__MODULE__{
          metric_name: String.t(),
          value: String.t(),
          timestamp: String.t()
        }

  defstruct metric_name: nil,
            value: nil,
            timestamp: nil
end

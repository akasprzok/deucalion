defmodule Deucalion.Sample do
  @type t :: %__MODULE__{
          metric_name: String.t(),
          value: String.t(),
          timestamp: String.t(),
          labels: list()
        }

  defstruct metric_name: nil,
            value: nil,
            timestamp: nil,
            labels: []
end

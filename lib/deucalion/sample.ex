defmodule Deucalion.Sample do
  @type label :: {String.t(), term}

  @type t :: %__MODULE__{
          metric_name: String.t(),
          value: String.t(),
          timestamp: String.t(),
          labels: label()
        }

  defstruct metric_name: nil,
            value: nil,
            timestamp: nil,
            labels: []
end

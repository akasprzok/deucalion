defmodule Deucalion.Sample do
  @moduledoc """
    A metric sample of the syntax

      metric_name [
        "{" label_name "=" `"` label_value `"` { "," label_name "=" `"` label_value `"` } [ "," ] "}"
      ] value [ timestamp ]

    Each line must have a unique combination of metric names and labels.
  """

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

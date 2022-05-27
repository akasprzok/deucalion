defmodule Deucalion.TypeLine do
  alias Deucalion.MetricType

  @type t :: %__MODULE__{
          metric_name: String.t(),
          metric_type: MetricType.t()
        }

  defstruct metric_name: nil,
            metric_type: nil
end

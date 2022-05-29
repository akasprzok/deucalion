defmodule Deucalion.TypeLine do
  @moduledoc """
  A comment of the form "# TYPE <metric_name> <metric_type>.

  Both tokens are required.
  """

  alias Deucalion.MetricType

  @type t :: %__MODULE__{
          metric_name: String.t(),
          metric_type: MetricType.t()
        }

  @enforce_keys [:metric_name, :metric_type]
  defstruct metric_name: nil,
            metric_type: nil
end

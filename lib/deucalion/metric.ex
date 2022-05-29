defmodule Deucalion.Metric do
  @moduledoc """
  A complete metric - composite of optional HELP and TYPE lines, as well as a number of metric lines.
  """

  alias Deucalion.MetricType

  @type t :: %__MODULE__{
    metric_name: String.t(),
    labels: list(),
    type: MetricType.t(),
    value: String.t(),
    docstring: String.t()
  }

  @enforce_keys [:metric_name]

  defstruct metric_name: nil,
    labels: [],
    type: :untyped,
    value: nil,
    docstring: nil
end

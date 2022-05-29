defmodule Deucalion.MetricType do
  @moduledoc """
  The 5 metric types supported by Prometheus.
  """
  @type t :: :counter | :gauge | :histogram | :summary | :untyped
end

defmodule Deucalion.MetricType do
  @type t :: :counter | :gauge | :histogram | :summary | :untyped
end

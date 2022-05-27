defmodule Deucalion.TypeLine do
  @type metric_type :: :counter | :gauge | :histogram | :summary

  @type t :: %__MODULE__{
    metric_name: String.t(),
    metric_type: metric_type()
  }

  defstruct metric_name: nil,
    metric_type: nil
end

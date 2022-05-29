defmodule Deucalion.HelpLine do
  @moduledoc """
  A comment line of the format "# HELP <metric_name> <docstring>".
  The docstring is considered optional.
  Only one HELP line may exist for the same metric name.
  """

  alias Deucalion.Metric

  @type t :: %__MODULE__{
          metric_name: String.t(),
          docstring: String.t()
        }

  @enforce_keys [:metric_name]

  defstruct metric_name: nil,
            docstring: nil

  def to_metric(line) do
    %Metric{
      metric_name: line.metric_name,
      docstring: line.docstring
    }
  end

  def merge(%__MODULE__{metric_name: metric_name}, %Metric{metric_name: metric_name, docstring: docstring}) do
    {:error, ["Metric ", metric_name, " already contains docstring ", docstring]}
  end
end

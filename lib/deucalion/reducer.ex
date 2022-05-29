defmodule Deucalion.Reducer do
  @moduledoc """
  Takes a list of Comment, Help, Type, and Sample lines and reduces them to metrics.

  Functions as a validator that Prometheus conventions are followed.

  Named Reducer until I can think of a name not quite as bad.
  """

  alias Deucalion.{CommentLine, HelpLine, Metric, Sample, TypeLine}

  @type lines :: [CommentLine | HelpLine | Sample | TypeLine]

  @spec to_metrics(lines) :: {:ok, map()} | {:error, term}
  def to_metrics(lines) do
    lines
    |> Enum.reduce(%{}, &add_metric/2)
  end

  defp add_metric(%CommentLine{}, metrics) do
    metrics
  end

  defp add_metric(%HelpLine{metric_name: metric_name} = line, metrics) do
    metrics
    |> Map.update(metric_name, HelpLine.to_metric(line), fn existing_value ->
      HelpLine.merge(line, existing_value)
     end)
  end
end

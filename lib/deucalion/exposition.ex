defmodule Deucalion.Exposition do
  @moduledoc """
  An exposition is a collection of MetricFamilies.
  This is the result of successfully parsing the Prometheus text format.
  """
  @type t :: [Deucalion.MetricFamily.t()]
end

defmodule Deucalion.MetricFamily do
  @moduledoc """
  A MetricFamily is a collection of metrics with a unique name.
  Each metric within it must have a unique set of LabelPair fields.
  """
  alias Deucalion.Metric

  @type labels :: %{String.t() => String.t()}
  @type t :: %__MODULE__{
          name: String.t(),
          type: Deucalion.MetricType.t(),
          help: String.t(),
          metrics: %{labels => Deucalion.Metric.t()}
        }

  @enforce_keys [:name]
  defstruct name: nil,
            type: :untyped,
            help: nil,
            metrics: %{}

  @spec from_tokens(keyword()) :: t() | nil
  def from_tokens([{:comment_type, "HELP"} | fields]) do
    struct!(__MODULE__, fields)
  end

  def from_tokens([{:comment_type, "TYPE"} | fields]) do
    struct!(__MODULE__, fields)
  end

  def from_tokens([{:name, name} | opts]) do
    [{:labels, labels} | metric_opts] = opts
    %__MODULE__{name: name, metrics: %{labels => struct!(Metric, metric_opts)}}
  end

  def from_tokens(comment: _comment), do: nil
  def from_tokens([]), do: nil

  def merge(family1, family2) do
    family1
    |> Map.merge(Map.from_struct(family2), &do_merge/3)
  end

  # names must match
  defp do_merge(:name, name, name), do: name

  # can only go to a type from an untyped family
  defp do_merge(:type, :untyped, type), do: type
  defp do_merge(:type, type, :untyped), do: type

  # can only add help if there isn't one
  defp do_merge(:help, nil, help), do: help
  defp do_merge(:help, help, nil), do: help

  defp do_merge(:metrics, metrics1, metrics2), do: Map.merge(metrics1, metrics2)
end

defmodule Deucalion.Metric do
  @moduledoc false
  @type t :: %__MODULE__{
          value: nil,
          timestamp: integer() | nil
        }

  @enforce_keys [:value]
  defstruct value: nil,
            timestamp: nil
end

defmodule Deucalion.Value do
  @moduledoc """
  Value is a float represented as required by Go's ParseFloat() function. In addition to standard numerical values, NaN, +Inf, and -Inf are valid values representing not a number, positive infinity, and negative infinity, respectively.
  """

  @type t :: float()

  @spec parse(binary()) :: {:ok, float() | String.t()} | {:error, term()}
  def parse("+Inf"), do: "+Inf"
  def parse("-Inf"), do: "-Inf"
  def parse("NaN"), do: "Nan"

  def parse(binary) do
    binary
    |> Float.parse()
    |> case do
      {float, ""} ->
        float
    end
  end
end

defmodule Deucalion.MetricType do
  @moduledoc """
  The 5 metric types supported by Prometheus.
  """
  @type t :: :counter | :gauge | :histogram | :summary | :untyped

  #@valid_values [:counter, :gauge, :histogram, :summary, :untyped]

  @spec parse(binary()) :: t()
  def parse(binary) do
    binary
    |> String.to_existing_atom()
  end
end

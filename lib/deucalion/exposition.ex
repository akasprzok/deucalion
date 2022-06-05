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
end

defmodule Deucalion.Metric do
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

  @valid_values [:counter, :gauge, :histogram, :summary, :untyped]

  @spec parse(binary()) :: t()
  def parse(binary) do
    binary
    |> String.to_existing_atom()
  end
end

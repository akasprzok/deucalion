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
  @type t :: %__MODULE__{
          name: String.t(),
          type: Deucalion.MetricType.t(),
          help: String.t(),
          metrics: list(Deucalion.Metric.t())
        }

  @enforce_keys [:name]
  defstruct name: nil,
            type: :untyped,
            help: nil,
            metrics: []
end

defmodule Deucalion.Metric do
  @type t :: %__MODULE__{
          label_pairs: nil,
          value: nil,
          timestamp: integer() | nil
        }

  @enforce_keys [:label_pairs, :value]
  defstruct label_pairs: nil,
            value: nil,
            timestamp: nil
end

defmodule Deucalion.Value do
  @type t :: float()

  @spec parse(binary()) :: {:ok, float()} | {:error, term()}
  def parse(binary) do
    binary
    |> Float.parse()
    |> case do
      {float, ""} ->
        {:ok, float}

      {_, remainder} ->
        {:error, "Unexpected remaineder #{remainder} when attempting to parse #{binary}"}

      :error ->
        {:error, :error}
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

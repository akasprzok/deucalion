defmodule Deucalion.HelpLine do
  @moduledoc """
  A comment line of the format "# HELP <metric_name> <docstring>".
  The docstring is considered optional.
  Only one HELP line may exist for the same metric name.
  """
  @type t :: %__MODULE__{
          metric_name: String.t(),
          docstring: String.t()
        }

  @enforce_keys [:metric_name]

  defstruct metric_name: nil,
            docstring: nil
end

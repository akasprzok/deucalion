defmodule Deucalion.CommentLine do
  @moduledoc """
  A comment line is a line with a `#` as the first non-whitespace character.

  If followed by HELP or TYPE, those lines are treated as Deucalion.HelpLine and Deucalion.CommentLine, respectively
  """

  @type t :: %__MODULE__{
          comment: String.t()
        }

  defstruct comment: nil
end

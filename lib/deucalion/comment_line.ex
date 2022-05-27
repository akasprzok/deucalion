defmodule Deucalion.CommentLine do
  @type t :: %__MODULE__{
          comment: String.t()
        }

  defstruct comment: nil
end

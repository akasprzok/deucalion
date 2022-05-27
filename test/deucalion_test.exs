defmodule DeucalionTest do
  use ExUnit.Case
  doctest Deucalion

  alias Deucalion.{HelpLine, TypeLine, CommentLine, Sample}

  @help_line "# HELP i_am_a_metric_name This is a docstring"
  @type_line "# TYPE i_am_a_metric_name gauge"
  @comment_line "# I am a comment"
  @sample "i_am_a_metric_name 7744"

  test "parses a help line" do
    assert Deucalion.parse_line(@help_line) == %HelpLine{
             metric_name: "i_am_a_metric_name",
             docstring: "This is a docstring"
           }
  end

  test "parses a type line" do
    assert Deucalion.parse_line(@type_line) == %TypeLine{
             metric_name: "i_am_a_metric_name",
             metric_type: "gauge"
           }
  end

  test "parses a comment" do
    assert Deucalion.parse_line(@comment_line) == %CommentLine{
             comment: "I am a comment"
           }
  end

  test "parses a sample" do
    assert Deucalion.parse_line(@sample) == %Sample{
             metric_name: "i_am_a_metric_name",
             value: "7744"
           }
  end
end

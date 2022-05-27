defmodule DeucalionTest do
  use ExUnit.Case
  doctest Deucalion

  @help_line "# HELP i_am_a_metric_name This is a description"
  @type_line "# TYPE i_am_a_metric_name gauge"

  test "parses a help line" do
    assert Deucalion.parse_line(@help_line) == :world
  end

  test "parses a type line" do
    assert Deucalion.parse_line(@type_line) == :world
  end
end

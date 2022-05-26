defmodule DeucalionTest do
  use ExUnit.Case
  doctest Deucalion

  test "greets the world" do
    assert Deucalion.hello() == :world
  end
end

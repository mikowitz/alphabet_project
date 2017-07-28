defmodule AlphabetProjectTest do
  use ExUnit.Case
  doctest AlphabetProject

  test "greets the world" do
    assert AlphabetProject.hello() == :world
  end
end

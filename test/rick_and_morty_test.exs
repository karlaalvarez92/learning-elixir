defmodule RickAndMortyTest do
  use ExUnit.Case
  doctest RickAndMorty

  test "greets the world" do
    assert RickAndMorty.hello() == :world
  end
end

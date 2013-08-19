Code.require_file "test_helper.exs", __DIR__

defmodule ParallelTest do
  use ExUnit.Case

  import Parallel

  test :map do
    assert_map 1..10
  end

  test :random_map do
    :random.seed(:erlang.now())
    Enum.each 1..50, fn(_) ->
      list = Enum.map 1..50, function :random.uniform/1
      assert_map list
    end
  end

  test :each do
    IO.puts "each"
    myself = self()
    collection = [1,2,3,4,5]
    each(collection, fn i -> myself <- {:test, i} end)
    Enum.each(collection, fn i ->
      receive do
        {:test, i} -> :ok
      after 100 ->
        assert false, "No result received"
      end
    end)
  end

  defp assert_map(list) do
    func = fn(x) -> x + 1 end
    assert Enum.sort(Enum.map(list, func)) == Enum.sort(map(list, func))
  end

end

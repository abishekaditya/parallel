defmodule Parallel do

  def map(collection, fun, options // []) do
    acc = {fun, pool(fun, options), [], []}
    {_, _, busy, acc} = Enumerable.reduce(collection, acc, function(execute/2) )
    List.concat(acc, consume(busy))
  end

  def each(collection, fun, options // []) do
    acc = {fun, pool(fun, options), [], []}
    Enumerable.reduce(collection, acc, function(execute/2) )
    nil
 end

  # Private

  defp execute(item, {fun, free = [], busy, acc}) do
    receive do
      {ref, from, result} ->
        from <- {ref, self(), fun, item}
        {fun, free, busy, [result|acc]}
    end
  end
  defp execute(item, {fun, [worker = {ref, pid}|free], busy, acc}) do
    pid <- {ref, self(), fun, item}
    {fun, free, [worker|busy], acc}
  end

  defp consume(pool) do
    Enum.map(pool, fn {ref, pid} ->
      receive do
        {^ref, ^pid, result} -> result
      end
    end)
  end

  def worker(fun) do
    receive do
      {ref, sender, fun, item} when is_function(fun) ->
        sender <- {ref, self, fun.(item)}
        worker(fun)
      :exit ->
        :ok
    end
  end

  defp pool(fun, options) do
    size = Keyword.get(options, :size) || :erlang.system_info(:schedulers)
    spawn_worker = fn -> {make_ref(), spawn_link(fn -> worker(fun) end)} end
    Stream.repeatedly(spawn_worker) |> Enum.take(size)
  end

end

defmodule PitchGenerator.V1 do
  @letters ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  def ordered_coordinates(letter) do
    {:ok, json} = File.read("processing/GraphParser/data/coordinates/#{letter}.json")
    letter_coordinates = Poison.Parser.parse!(json) |> Enum.map(&List.to_tuple/1) |> Enum.into(%{})
    Enum.sort_by(letter_coordinates, fn {i, _} -> i end)
  end

  def processed_summed_coords do
    all_ys = Enum.map(summed_coordinates, fn {x, y} -> y end)
    min = Enum.min(all_ys)
    max = Enum.max(all_ys)
    [min, max]
    summed_coordinates
    |> Enum.map(fn {x, y} ->
      {x, Float.floor(__MODULE__.map(y, min, max, 1, 24))}
    end)
  end

  def summed_coordinates do
    all_coords = Enum.map(@letters, &ordered_coordinates/1)
    measure_count = length(List.first(all_coords))
    IO.inspect measure_count
    Enum.map(0..measure_count-1, fn i ->
      sum = Enum.map(all_coords, fn coords ->
         {^i, y} = Enum.find(coords, fn {x, _} -> x == i end)
         y
      end) |> Enum.sum
      {i, sum}
    end)
  end

  def map(v, start_c, stop_c, start_t, stop_t) do
    start_t + (stop_t - start_t) * ((v - start_c) / (stop_c - start_c))
  end
end


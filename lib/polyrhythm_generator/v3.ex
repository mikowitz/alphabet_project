defmodule PolyrhythmGenerator.V3 do
  import PolyrhythmGenerator

  def pulse_part(letter) do
    ordered_coordinates(letter)
    |> Enum.map(fn _ ->
      %Measure{
        time_signature: {4, 4}, tuplet: nil,
        events: (Stream.cycle(["c16"]) |> Enum.take(16))
      }
    end)
  end

  def letter_part(letter, pulse) do
    part_ratios(letter, pulse)
    |> Enum.map(fn n ->
      %Measure{
        time_signature: nil, tuplet: {n, 16},
        events: (Stream.cycle(["c16"]) |> Enum.take(n))
      }
    end)
  end

  def pulse_ratios(letter) do
    coordinates = ordered_coordinates(letter)
    {_index, max_y} = Enum.max_by(coordinates, fn {_x, y} -> y end)
    Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end)
  end

  def part_ratios(letter, pulse) do
    pulse = pulse_ratios(pulse)
    coordinates = ordered_coordinates(letter)
    {_index, max_y} = Enum.max_by(coordinates, fn {_, y} -> y end)
    pulse = Enum.into(pulse, %{})
    coords = Enum.into(Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end), %{})
    ratios = Enum.sort(Map.keys(coords))
    |> Enum.map(fn i ->
      {pn, pd} = pulse[i]
      {n, d} = coords[i]
      reduce(n * pd, d * pn)
    end) |> Enum.map(fn {x, y} -> x / y end)
    {letter_min, letter_max} = Enum.min_max(ratios)
    Enum.map(ratios, &__MODULE__.map(&1, letter_min, letter_max, 1/16, 2))
      |> Enum.map(fn x -> round(x * 16) end)
  end

  def reduce(a, b) do
    with g <- Integer.gcd(a, b) do
      {round(a / g), round(b / g)}
    end
  end

  def map(v, start_c, stop_c, start_t, stop_t) do
    start_t + (stop_t - start_t) * ((v - start_c) / (stop_c - start_c))
  end
end



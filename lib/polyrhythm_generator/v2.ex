defmodule PolyrhythmGenerator.V2 do
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
    music = part_ratios(letter, pulse)
    |> Enum.map(fn n ->
      %Measure{
        time_signature: nil, tuplet: {n, 16},
        events: (Stream.cycle(["c16"]) |> Enum.take(n))
      }
    end)
  end

  def pulse_ratios(letter) do
    coordinates = ordered_coordinates(letter)
    {index, max_y} = Enum.max_by(coordinates, fn {x, y} -> y end)
    Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end)
  end

  def part_ratios(letter, pulse) do
    pulse = pulse_ratios(pulse) |> Enum.into(%{})
    coordinates = ordered_coordinates(letter)
    {index, max_y} = Enum.max_by(coordinates, fn {x, y} -> y end)
    coords = Enum.into(Enum.map(coordinates, fn {x, y} -> {x, reduce(y, max_y)} end), %{})
    Enum.sort(Map.keys(coords))
    |> Enum.map(fn i ->
      {pn, pd} = pulse[i]
      {n, d} = coords[i]
      reduce(n * pd, d * pn)
    end) |> Enum.map(fn {x, y} -> round(16 * x / y) end)
  end

  def reduce(a, b) do
    with g <- Integer.gcd(a, b) do
      {round(a / g), round(b / g)}
    end
  end
end

